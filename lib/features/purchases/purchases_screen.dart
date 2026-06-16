import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/branch/branch_filter_scope.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/part_model.dart';
import '../../data/models/purchase_order_model.dart';
import '../../data/models/user_role.dart';
import '../../data/models/branch_model.dart';
import '../../data/repositories/part_repository.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../di/injection.dart';
import '../shared/branch_dropdown.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import 'purchase_create_dialog.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<PurchaseOrderModel>? _items;
  String? _error;
  bool _loading = true;
  String? _receivingId;

  @override
  void initState() {
    super.initState();
    getIt<AppRefreshBus>().addListener(_onAppRefresh);
    _load();
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onAppRefresh);
    super.dispose();
  }

  void _onAppRefresh(AppRefreshKind kind) {
    if (!mounted) return;
    if (kind == AppRefreshKind.branchFilter) _load();
  }

  Future<void> _load() async {
    AppLogger.action('purchases.load');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<PurchaseRepository>().list(
        branchId: apiBranchIdFromContext(context),
      );
      for (final p in items) {
        AppLogger.action('purchases.row', {
          'id': p.id,
          'status': p.status,
          'receivedAt': p.receivedAt?.toIso8601String(),
          'canReceive': p.canReceive,
          'supplier': p.supplierName,
        });
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.error('purchases.load.failed', e, st);
      if (!mounted) return;
      setState(() {
        _error = _messageFrom(e);
        _loading = false;
      });
    }
  }

  String _messageFrom(Object e) {
    if (e is DioException) return AppLogger.dioMessage(e);
    return e.toString();
  }

  Future<void> _receivePurchase(
    BuildContext context,
    PurchaseOrderModel purchase,
  ) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final userCanReceive =
        RolePermissions.canPerform(AppAction.purchaseReceive, role);

    AppLogger.action('purchases.receive.tap', {
      'id': purchase.id,
      'status': purchase.status,
      'receivedAt': purchase.receivedAt?.toIso8601String(),
      'canReceive': purchase.canReceive,
      'userCanReceive': userCanReceive,
      'role': role.name,
    });

    if (!userCanReceive) {
      AppLogger.warning('purchases.receive.denied.role');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.somethingWentWrong)),
      );
      return;
    }

    if (!purchase.canReceive) {
      AppLogger.warning('purchases.receive.denied.status');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.purchaseAlreadyReceived)),
      );
      return;
    }

    final branchId = purchase.branchId ??
        apiBranchIdFromContext(context) ??
        context.read<AuthCubit>().state.user?.branchId;
    setState(() => _receivingId = purchase.id);

    try {
      await getIt<PurchaseRepository>().receive(
        purchase.id,
        branchId: branchId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.activityPurchaseReceived),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await _load();
    } on DioException catch (e, st) {
      AppLogger.error('purchases.receive.failed', e, st);
      if (!mounted) return;
      if (e.response?.statusCode == 422 &&
          AppLogger.apiResponseMessageContains(e, 'already received')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseAlreadyReceived)),
        );
        await _load();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFrom(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e, st) {
      AppLogger.error('purchases.receive.failed', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFrom(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _receivingId = null);
    }
  }

  Future<void> _cancelPurchase(BuildContext context, String id) async {
    AppLogger.action('purchases.cancel.tap', {'id': id});
    setState(() => _receivingId = id);
    try {
      await getIt<PurchaseRepository>().cancel(id);
      if (!mounted) return;
      await _load();
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
    } catch (e, st) {
      AppLogger.error('purchases.cancel.failed', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFrom(e))),
      );
    } finally {
      if (mounted) setState(() => _receivingId = null);
    }
  }

  Future<void> _showCreateForm(BuildContext context) async {
    AppLogger.action('purchases.create.open');
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.purchaseCreate, role)) {
      AppLogger.warning('purchases.create.denied.role');
      return;
    }

    final user = context.read<AuthCubit>().state.user;
    final userBranchId = user?.branchId;

    List<SupplierModel> suppliers = [];
    List<PartModel> parts = [];
    List<BranchModel> branches = [];
    try {
      suppliers = await getIt<SupplierRepository>().list(
        branchId: apiBranchIdFromContext(context) ?? userBranchId,
      );
      parts = await getIt<PartRepository>().list(perPage: 200);
      branches = await loadActiveBranches(
        allowedIds: user?.accessibleBranchIds,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFrom(e))),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (branches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.branchRequired)),
      );
      return;
    }

    var selectedBranchId = userBranchId;
    if (selectedBranchId == null ||
        !branches.any((b) => b.id == selectedBranchId)) {
      selectedBranchId = branches.first.id;
    }
    final showBranchPicker =
        user?.canSelectBranch == true || userBranchId == null;

    final result = await showDialog<PurchaseCreateDialogResult>(
      context: context,
      builder: (ctx) => PurchaseCreateDialog(
        suppliers: suppliers,
        parts: parts,
        branches: branches,
        initialBranchId: selectedBranchId!,
        showBranchPicker: showBranchPicker,
      ),
    );

    if (result == null) return;

    final body = <String, dynamic>{
      'supplier_id': result.supplierId,
      'branch_id': result.branchId,
      'description': result.description,
      'payment_type': result.paymentType,
      'items': [
        for (final l in result.lines)
          {
            'part_id': l.partId,
            'quantity': l.quantity,
            'unit_cost': l.unitCost,
          },
      ],
    };
    if (result.paymentType == 'installments') {
      body['installment_count'] = result.installmentCount;
      body['installment_start_date'] = result.installmentStartDate;
    }

    try {
      AppLogger.action('purchases.create.submit', body);
      await getIt<PurchaseRepository>().create(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseSaved)),
        );
      }
      await _load();
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
    } catch (e, st) {
      AppLogger.error('purchases.create.failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFrom(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.purchaseCreate, role);
    final canReceive = RolePermissions.canPerform(AppAction.purchaseReceive, role);
    final canCancel = RolePermissions.canPerform(AppAction.purchaseCancel, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.purchasesTitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: () => _showCreateForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.newPurchase),
              ),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : EntityListView(
                      itemCount: _items!.length,
                      emptyMessage: l10n.noData,
                      itemBuilder: (context, i) {
                        final p = _items![i];
                        final showReceive = canReceive && p.canReceive;
                        final isBusy = _receivingId == p.id;
                        return EntityListTile(
                          title:
                              '${l10n.purchaseOrder} ${p.id.length > 8 ? p.id.substring(0, 8) : p.id}',
                          subtitle:
                              '${p.supplierName ?? ''} · ${localizeApiStatus(context, p.status)}'
                              '${kDebugMode ? ' · received=${p.receivedAt != null}' : ''}',
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showReceive)
                                FilledButton.tonal(
                                  onPressed: isBusy
                                      ? null
                                      : () => _receivePurchase(context, p),
                                  child: isBusy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(l10n.receive),
                                ),
                              if (canCancel && p.canCancel)
                                IconButton(
                                  tooltip: l10n.cancel,
                                  icon: const Icon(Icons.cancel_outlined),
                                  onPressed: isBusy
                                      ? null
                                      : () => _cancelPurchase(context, p.id),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
