import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/settings/settings_service.dart';
import '../../core/utils/sale_quantity.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/invoice_repository.dart';

class PosLine extends Equatable {
  const PosLine({
    required this.partId,
    required this.code,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.available,
    this.unit,
    this.imageUrl,
  });

  final String partId;
  final String code;
  final String name;
  final double unitPrice;
  final double quantity;
  final double available;
  final String? unit;
  final String? imageUrl;

  double get lineTotal => unitPrice * quantity;

  PosLine copyWith({double? quantity, double? unitPrice, double? available}) =>
      PosLine(
        partId: partId,
        code: code,
        name: name,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
        available: available ?? this.available,
        unit: unit,
        imageUrl: imageUrl,
      );

  @override
  List<Object?> get props => [partId, quantity, unitPrice];
}

class PosState extends Equatable {
  const PosState({
    this.lines = const [],
    this.customers = const [],
    this.searchResults = const [],
    this.customerId,
    this.paymentType = 'cash',
    this.discount = 0,
    this.amountPaid = 0,
    this.loading = false,
    this.completing = false,
    this.error,
    this.lastLocalId,
    this.lastServerId,
    this.lastAmountPaid,
    this.lastChange,
  });

  final List<PosLine> lines;
  final List<Customer> customers;
  final List<Part> searchResults;
  final String? customerId;
  final String paymentType;
  final double discount;
  final double amountPaid;
  final bool loading;
  final bool completing;
  final String? error;
  final String? lastLocalId;
  final String? lastServerId;
  final double? lastAmountPaid;
  final double? lastChange;

  double get subtotal =>
      lines.fold(0.0, (sum, l) => sum + l.lineTotal);

  double get total => subtotal - discount;

  bool get isCash => paymentType == 'cash';

  double get change =>
      isCash && amountPaid > total ? amountPaid - total : 0;

  bool get canCompleteCash =>
      !isCash || (amountPaid >= total && total > 0);

  @override
  List<Object?> get props => [
        lines,
        customers,
        searchResults,
        customerId,
        paymentType,
        discount,
        amountPaid,
        loading,
        completing,
        error,
        lastLocalId,
        lastServerId,
        lastAmountPaid,
        lastChange,
      ];
}

abstract class PosEvent extends Equatable {
  const PosEvent();
  @override
  List<Object?> get props => [];
}

class PosLoad extends PosEvent {
  const PosLoad({this.silent = false});
  final bool silent;
  @override
  List<Object?> get props => [silent];
}

class PosSearch extends PosEvent {
  const PosSearch(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class PosAddLine extends PosEvent {
  const PosAddLine(this.part, this.branchId);
  final Part part;
  final String branchId;
  @override
  List<Object?> get props => [part, branchId];
}

class PosUpdateQty extends PosEvent {
  const PosUpdateQty(this.partId, this.qty);
  final String partId;
  final double qty;
  @override
  List<Object?> get props => [partId, qty];
}

class PosRemoveLine extends PosEvent {
  const PosRemoveLine(this.partId);
  final String partId;
  @override
  List<Object?> get props => [partId];
}

class PosSetCustomer extends PosEvent {
  const PosSetCustomer(this.id);
  final String? id;
  @override
  List<Object?> get props => [id];
}

class PosSetPayment extends PosEvent {
  const PosSetPayment(this.type);
  final String type;
  @override
  List<Object?> get props => [type];
}

class PosSetDiscount extends PosEvent {
  const PosSetDiscount(this.amount);
  final double amount;
  @override
  List<Object?> get props => [amount];
}

class PosSetAmountPaid extends PosEvent {
  const PosSetAmountPaid(this.amount);
  final double amount;
  @override
  List<Object?> get props => [amount];
}

class PosSetUnitPrice extends PosEvent {
  const PosSetUnitPrice(this.partId, this.unitPrice);
  final String partId;
  final double unitPrice;
  @override
  List<Object?> get props => [partId, unitPrice];
}

class PosComplete extends PosEvent {
  const PosComplete(this.branchId);
  final String branchId;
  @override
  List<Object?> get props => [branchId];
}

class PosClearCart extends PosEvent {
  const PosClearCart();
}

/// Clears [lastLocalId] / [lastServerId] after receipt navigation so a new sale
/// does not re-open the previous receipt.
class PosAcknowledgeSale extends PosEvent {
  const PosAcknowledgeSale();
}

/// Re-reads on-hand qty for cart lines from local cache (after sync or sale).
class PosRefreshStock extends PosEvent {
  const PosRefreshStock(this.branchId);
  final String branchId;
  @override
  List<Object?> get props => [branchId];
}

class PosBloc extends Bloc<PosEvent, PosState> {
  PosBloc(
    this._db,
    this._invoiceRepo,
    this._connectivity,
    this._settings,
  ) : super(const PosState()) {
    on<PosLoad>(_onLoad);
    on<PosSearch>(_onSearch);
    on<PosAddLine>(_onAddLine);
    on<PosUpdateQty>(_onUpdateQty);
    on<PosRemoveLine>(_onRemoveLine);
    on<PosSetCustomer>(_onSetCustomer);
    on<PosSetPayment>(_onSetPayment);
    on<PosSetDiscount>(_onSetDiscount);
    on<PosSetAmountPaid>(_onSetAmountPaid);
    on<PosSetUnitPrice>(_onSetUnitPrice);
    on<PosComplete>(_onComplete);
    on<PosClearCart>(_onClear);
    on<PosAcknowledgeSale>(_onAcknowledgeSale);
    on<PosRefreshStock>(_onRefreshStock);
  }

  final AppDatabase _db;
  final InvoiceRepository _invoiceRepo;
  final ConnectivityCubit _connectivity;
  final SettingsService _settings;

  PosState _withCashTender(PosState s) {
    if (!s.isCash || s.total <= 0) return s;
    if (s.amountPaid < s.total) {
      return s.copyWith(amountPaid: s.total);
    }
    return s;
  }

  String? _defaultCustomerId(List<Customer> customers) {
    if (customers.isEmpty) return null;
    for (final c in customers) {
      final name = c.name.trim();
      if (name == 'نقدي' || name.toLowerCase() == 'cash') return c.id;
    }
    return customers.first.id;
  }

  Future<void> _onLoad(PosLoad event, Emitter<PosState> emit) async {
    if (!event.silent) {
      emit(state.copyWith(loading: true, error: null));
    }
    try {
      final customers = await _db.getActiveCustomers();
      final parts = await _db.searchParts('', limit: 50);
      emit(state.copyWith(
        loading: false,
        customers: customers,
        customerId: state.customerId ?? _defaultCustomerId(customers),
        searchResults: parts,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onRefreshStock(
    PosRefreshStock event,
    Emitter<PosState> emit,
  ) async {
    if (state.lines.isEmpty) return;
    final updated = <PosLine>[];
    for (final line in state.lines) {
      final available = await _db.getStockQty(line.partId, event.branchId);
      updated.add(line.copyWith(available: available));
    }
    emit(state.copyWith(lines: updated));
  }

  Future<void> _onSearch(PosSearch event, Emitter<PosState> emit) async {
    final results = await _db.searchParts(event.query);
    emit(state.copyWith(searchResults: results));
  }

  Future<void> _onAddLine(PosAddLine event, Emitter<PosState> emit) async {
    final unit = event.part.unit;
    final step = saleQuantityStep(unit);
    final available = await _db.getStockQty(event.part.id, event.branchId);
    final existing = state.lines.indexWhere((l) => l.partId == event.part.id);
    if (existing >= 0) {
      final line = state.lines[existing];
      final nextQty = normalizeSaleQuantity(line.quantity + step, unit);
      final updated = line.copyWith(quantity: nextQty);
      if (!hasEnoughStock(updated.quantity, available)) {
        emit(state.copyWith(error: 'insufficient_stock:${event.part.code}'));
        return;
      }
      final lines = [...state.lines]..[existing] = updated;
      emit(_withCashTender(state.copyWith(lines: lines, error: null)));
    } else {
      final initialQty = defaultSaleQuantity(unit);
      if (!hasEnoughStock(initialQty, available)) {
        emit(state.copyWith(error: 'no_stock:${event.part.code}'));
        return;
      }
      emit(_withCashTender(state.copyWith(
        lines: [
          ...state.lines,
          PosLine(
            partId: event.part.id,
            code: event.part.code,
            name: event.part.name,
            unitPrice: event.part.sellPrice,
            quantity: initialQty,
            available: available,
            unit: unit,
            imageUrl: event.part.imageUrl,
          ),
        ],
        error: null,
      )));
    }
  }

  void _onUpdateQty(PosUpdateQty event, Emitter<PosState> emit) {
    final index = state.lines.indexWhere((l) => l.partId == event.partId);
    if (index < 0) return;
    final line = state.lines[index];
    final qty = normalizeSaleQuantity(event.qty, line.unit);
    if (isSaleQuantityTooLow(qty, line.unit)) {
      emit(_withCashTender(state.copyWith(
        lines: state.lines.where((l) => l.partId != event.partId).toList(),
      )));
      return;
    }
    if (!hasEnoughStock(qty, line.available)) {
      emit(state.copyWith(error: 'insufficient_stock:${line.code}'));
      return;
    }
    final lines = state.lines.map((l) {
      if (l.partId != event.partId) return l;
      return l.copyWith(quantity: qty);
    }).toList();
    emit(_withCashTender(state.copyWith(lines: lines, error: null)));
  }

  void _onRemoveLine(PosRemoveLine event, Emitter<PosState> emit) {
    emit(_withCashTender(state.copyWith(
      lines: state.lines.where((l) => l.partId != event.partId).toList(),
    )));
  }

  void _onSetCustomer(PosSetCustomer event, Emitter<PosState> emit) {
    emit(state.copyWith(customerId: event.id));
  }

  void _onSetPayment(PosSetPayment event, Emitter<PosState> emit) {
    final isCash = event.type == 'cash';
    emit(state.copyWith(
      paymentType: event.type,
      amountPaid: isCash ? state.total : 0,
      clearError: true,
    ));
  }

  void _onSetDiscount(PosSetDiscount event, Emitter<PosState> emit) {
    emit(_withCashTender(state.copyWith(discount: event.amount)));
  }

  void _onSetAmountPaid(PosSetAmountPaid event, Emitter<PosState> emit) {
    emit(state.copyWith(amountPaid: event.amount, clearError: true));
  }

  void _onSetUnitPrice(PosSetUnitPrice event, Emitter<PosState> emit) {
    final lines = state.lines.map((l) {
      if (l.partId != event.partId) return l;
      return l.copyWith(unitPrice: event.unitPrice);
    }).toList();
    emit(_withCashTender(state.copyWith(lines: lines, clearError: true)));
  }

  void _onClear(PosClearCart event, Emitter<PosState> emit) {
    emit(state.copyWith(
      lines: [],
      discount: 0,
      amountPaid: 0,
      error: null,
      clearSaleIds: true,
    ));
  }

  void _onAcknowledgeSale(PosAcknowledgeSale event, Emitter<PosState> emit) {
    emit(state.copyWith(clearSaleIds: true, clearCashTender: true));
  }

  Future<void> _onComplete(PosComplete event, Emitter<PosState> emit) async {
    if (state.customerId == null || state.lines.isEmpty) {
      emit(state.copyWith(error: 'select_customer'));
      return;
    }
    if (!_connectivity.state.isOnline &&
        state.paymentType == 'credit' &&
        _settings.offlineCashOnly) {
      emit(state.copyWith(error: 'credit_blocked'));
      return;
    }
    if (!_connectivity.state.isOnline && state.paymentType == 'credit') {
      emit(state.copyWith(error: 'credit_unavailable'));
      return;
    }

    if (state.lines.any((l) => l.unitPrice <= 0)) {
      emit(state.copyWith(error: 'invalid_line_price'));
      return;
    }

    if (state.isCash && !state.canCompleteCash) {
      emit(state.copyWith(error: 'insufficient_payment'));
      return;
    }

    emit(state.copyWith(completing: true, error: null));
    try {
      final items = state.lines
          .map(
            (l) => {
              'part_id': l.partId,
              'quantity': l.quantity,
              'unit_price': l.unitPrice,
            },
          )
          .toList();
      final meta = state.lines
          .map(
            (l) => (
              partId: l.partId,
              code: l.code,
              name: l.name,
              qty: l.quantity,
              price: l.unitPrice,
            ),
          )
          .toList();

      final result = await _invoiceRepo.create(
        customerId: state.customerId!,
        branchId: event.branchId,
        paymentType: state.paymentType,
        discount: state.discount,
        items: items,
        lineMeta: meta,
      );

      if (result.isOffline) {
        emit(state.copyWith(
          completing: false,
          lastLocalId: result.localId,
          lastServerId: null,
          lastAmountPaid: state.isCash ? state.amountPaid : null,
          lastChange: state.isCash ? state.change : null,
          lines: [],
          discount: 0,
          amountPaid: 0,
          clearSaleIds: false,
        ));
      } else {
        emit(state.copyWith(
          completing: false,
          lastServerId: result.invoice?.id,
          lastLocalId: null,
          lastAmountPaid: state.isCash ? state.amountPaid : null,
          lastChange: state.isCash ? state.change : null,
          lines: [],
          discount: 0,
          amountPaid: 0,
          clearSaleIds: false,
        ));
      }
    } on InsufficientStockException catch (e) {
      emit(state.copyWith(
        completing: false,
        error: e.message ?? 'insufficient_stock_generic',
      ));
    } catch (e) {
      emit(state.copyWith(completing: false, error: e.toString()));
    }
  }
}

extension on PosState {
  PosState copyWith({
    List<PosLine>? lines,
    List<Customer>? customers,
    List<Part>? searchResults,
    String? customerId,
    String? paymentType,
    double? discount,
    double? amountPaid,
    bool? loading,
    bool? completing,
    String? error,
    String? lastLocalId,
    String? lastServerId,
    double? lastAmountPaid,
    double? lastChange,
    bool clearError = false,
    bool clearSaleIds = false,
    bool clearCashTender = false,
  }) {
    return PosState(
      lines: lines ?? this.lines,
      customers: customers ?? this.customers,
      searchResults: searchResults ?? this.searchResults,
      customerId: customerId ?? this.customerId,
      paymentType: paymentType ?? this.paymentType,
      discount: discount ?? this.discount,
      amountPaid: amountPaid ?? this.amountPaid,
      loading: loading ?? this.loading,
      completing: completing ?? this.completing,
      error: clearError ? null : (error ?? this.error),
      lastLocalId: clearSaleIds
          ? null
          : (lastLocalId != null ? lastLocalId : this.lastLocalId),
      lastServerId: clearSaleIds
          ? null
          : (lastServerId != null ? lastServerId : this.lastServerId),
      lastAmountPaid: clearSaleIds || clearCashTender
          ? null
          : (lastAmountPaid ?? this.lastAmountPaid),
      lastChange: clearSaleIds || clearCashTender
          ? null
          : (lastChange ?? this.lastChange),
    );
  }
}
