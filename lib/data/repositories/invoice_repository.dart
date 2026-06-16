import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_utils.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../local/app_database.dart';
import '../models/invoice_model.dart';
import '../models/invoice_receipt_model.dart';
import 'package:drift/drift.dart' as drift;

class InvoiceCreateResult {
  const InvoiceCreateResult.online(this.invoice) : isOffline = false, localId = null;
  const InvoiceCreateResult.offline(this.localId)
      : isOffline = true,
        invoice = null;

  final bool isOffline;
  final String? localId;
  final InvoiceModel? invoice;
}

class InvoiceRepository {
  InvoiceRepository(
    this._dio,
    this._db,
    this._connectivity,
  );

  final Dio _dio;
  final AppDatabase _db;
  final ConnectivityCubit _connectivity;
  final _uuid = const Uuid();

  Future<List<InvoiceModel>> list({
    String? from,
    String? to,
    String? customerId,
    String? paymentType,
    String? branchId,
    int perPage = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '/invoices',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (customerId != null) 'customer_id': customerId,
        if (paymentType != null) 'payment_type': paymentType,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
        'per_page': perPage,
      },
    );
    return parseList(response.data, InvoiceModel.fromJson);
  }

  Future<List<InvoiceModel>> pendingCredit({String? branchId}) async {
    final response = await _dio.get<dynamic>(
      '/invoices/pending-credit',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(response.data, InvoiceModel.fromJson);
  }

  Future<InvoiceModel> get(String id) async {
    final response = await _dio.get<dynamic>('/invoices/$id');
    return InvoiceModel.fromJson(parseObject(response.data));
  }

  Future<InvoiceReceiptModel> receipt(String id) async {
    final response = await _dio.get<dynamic>('/invoices/$id/receipt');
    return InvoiceReceiptModel.fromJson(parseObject(response.data));
  }

  Future<void> cancel(String id) async {
    await _dio.patch('/invoices/$id/cancel');
  }

  Future<InvoiceCreateResult> create({
    required String customerId,
    required String branchId,
    required String paymentType,
    required double discount,
    required List<Map<String, dynamic>> items,
    required List<({String partId, String code, String name, double qty, double price})> lineMeta,
  }) async {
    final body = {
      'customer_id': customerId,
      'branch_id': branchId,
      'payment_type': paymentType,
      'discount': discount,
      'items': items,
    };

    if (_connectivity.state.isOnline) {
      try {
        final response = await _dio.post<dynamic>('/invoices', data: body);
        final invoice =
            InvoiceModel.fromJson(parseObject(response.data));
        for (final line in lineMeta) {
          await _db.decrementStock(line.partId, branchId, line.qty);
        }
        return InvoiceCreateResult.online(invoice);
      } on DioException catch (e) {
        if (e.response?.statusCode != 422) rethrow;
        throw _parseStockError(e);
      }
    }

    return _createOffline(
      customerId: customerId,
      branchId: branchId,
      paymentType: paymentType,
      discount: discount,
      items: items,
      lineMeta: lineMeta,
    );
  }

  Future<InvoiceCreateResult> _createOffline({
    required String customerId,
    required String branchId,
    required String paymentType,
    required double discount,
    required List<Map<String, dynamic>> items,
    required List<({String partId, String code, String name, double qty, double price})> lineMeta,
  }) async {
    for (final line in lineMeta) {
      final available = await _db.getStockQty(line.partId, branchId);
      if (available < line.qty) {
        throw InsufficientStockException([
          StockFailure(
            partId: line.partId,
            requested: line.qty,
            available: available,
          ),
        ]);
      }
    }

    final localId = _uuid.v4();
    var subtotal = 0.0;
    for (final line in lineMeta) {
      subtotal += line.qty * line.price;
    }
    final total = subtotal - discount;

    await _db.into(_db.pendingInvoices).insert(
          PendingInvoicesCompanion.insert(
            localId: localId,
            customerId: customerId,
            branchId: branchId,
            paymentType: paymentType,
            discount: drift.Value(discount),
            subtotal: subtotal,
            total: total,
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        );

    for (final line in lineMeta) {
      await _db.into(_db.pendingInvoiceItems).insert(
            PendingInvoiceItemsCompanion.insert(
              localInvoiceId: localId,
              partId: line.partId,
              partCode: line.code,
              partName: line.name,
              quantity: line.qty,
              unitPrice: line.price,
              lineTotal: line.qty * line.price,
            ),
          );
      await _db.decrementStock(line.partId, branchId, line.qty);
    }

    return InvoiceCreateResult.offline(localId);
  }

  Future<InvoiceModel> postPendingInvoice(String localId) async {
    final pending = await (_db.select(_db.pendingInvoices)
          ..where((p) => p.localId.equals(localId)))
        .getSingle();
    final itemRows = await _db.itemsForInvoice(localId);
    final body = {
      'customer_id': pending.customerId,
      'branch_id': pending.branchId,
      'payment_type': pending.paymentType,
      'discount': pending.discount,
      'items': itemRows
          .map(
            (i) => {
              'part_id': i.partId,
              'quantity': i.quantity,
              'unit_price': i.unitPrice,
            },
          )
          .toList(),
    };
    try {
      final response = await _dio.post<dynamic>('/invoices', data: body);
      return InvoiceModel.fromJson(parseObject(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) throw _parseStockError(e);
      rethrow;
    }
  }

  InsufficientStockException _parseStockError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['failures'] is List) {
      final failures = (data['failures'] as List)
          .map((f) => StockFailure.fromJson(f as Map<String, dynamic>))
          .toList();
      return InsufficientStockException(
        failures,
        message: data['message']?.toString(),
      );
    }
    return InsufficientStockException(
      const [],
      message: data is Map ? data['message']?.toString() : null,
    );
  }
}

class InsufficientStockException implements Exception {
  InsufficientStockException(this.failures, {this.message});
  final List<StockFailure> failures;
  final String? message;

  @override
  String toString() => message ?? 'Insufficient stock';
}
