import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/branch/branch_filter_scope.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/supplier_payables_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import 'pay_supplier_dialog.dart';

/// Grouped supplier payables — one section per supplier; pay against total debt.
class SupplierPayablesScreen extends StatefulWidget {
  const SupplierPayablesScreen({super.key});

  @override
  State<SupplierPayablesScreen> createState() => _SupplierPayablesScreenState();
}

class _SupplierPayablesScreenState extends State<SupplierPayablesScreen> {
  SupplierPayablesResponse? _data;
  String? _error;
  bool _loading = true;
  String? _payingSupplierId;

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
    if (kind == AppRefreshKind.dashboard ||
        kind == AppRefreshKind.branchFilter) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getIt<DashboardRepository>().payablesBySupplier(
        branchId: apiBranchIdFromContext(context),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _paySupplier(SupplierPayableGroup group) async {
    final l10n = context.l10n;
    final debt = group.totalDebt;
    if (debt <= 0) return;

    final result = await PaySupplierDialog.show(
      context,
      supplierName: group.supplier.name,
      totalDebt: debt,
    );
    if (result == null || !mounted) return;

    setState(() => _payingSupplierId = group.supplier.id);
    try {
      await getIt<SupplierRepository>().recordPayment(
        group.supplier.id,
        paymentMethod: result.paymentMethod,
        amount: result.payFullBalance ? null : result.amount,
        notes: result.notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.supplierPaidSuccess),
          backgroundColor: Colors.green.shade700,
        ),
      );
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?.toString() ?? e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _payingSupplierId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canPay = RolePermissions.canPerform(AppAction.installmentPay, role);
    final data = _data;
    final groups = data?.suppliers
            .where((g) => g.totalDebt > 0)
            .toList() ??
        const <SupplierPayableGroup>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.supplierPayablesTitle,
          subtitle: l10n.supplierPayablesSubtitle,
          actions: [
            if (data != null && data.totalSupplierDebt > 0)
              Chip(
                label: Text(formatMoney(context, data.totalSupplierDebt)),
                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
              ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : groups.isEmpty
                      ? Center(child: Text(l10n.noCreditors))
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final group = groups[i];
                            final isBusy = _payingSupplierId == group.supplier.id;
                            return Card(
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  child: Icon(
                                    Icons.local_shipping_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                                ),
                                title: Text(
                                  group.supplier.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  formatMoney(context, group.totalDebt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: AppColors.warning),
                                ),
                                trailing: canPay
                                    ? FilledButton(
                                        onPressed: isBusy
                                            ? null
                                            : () => _paySupplier(group),
                                        child: isBusy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(l10n.pay),
                                      )
                                    : null,
                                children: [
                                  if (group.purchaseOrders.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        4,
                                      ),
                                      child: Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text(
                                          l10n.purchasesTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                      ),
                                    ),
                                    for (final po in group.purchaseOrders)
                                      EntityListTile(
                                        title: '${po['id'] ?? '—'}'.length > 8
                                            ? '${po['id']}'.substring(0, 8)
                                            : '${po['id'] ?? '—'}',
                                        subtitle: po['status'] as String?,
                                        trailing: Text(
                                          formatMoney(
                                            context,
                                            (po['total'] as num?)?.toDouble(),
                                          ),
                                        ),
                                        leading: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                  if (group.installments.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        4,
                                      ),
                                      child: Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text(
                                          l10n.installmentsTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                      ),
                                    ),
                                    for (final inst in group.installments)
                                      EntityListTile(
                                        title: inst.installmentNo > 0
                                            ? '#${inst.installmentNo}'
                                            : formatMoney(
                                                context,
                                                inst.remainingBalance,
                                              ),
                                        subtitle: l10n.dueDate(
                                          inst.dueDate ?? '—',
                                        ),
                                        trailing: Text(
                                          formatMoney(
                                            context,
                                            inst.remainingBalance,
                                          ),
                                        ),
                                        leading: Icon(
                                          inst.isPaid
                                              ? Icons.check_circle_outline
                                              : Icons.payments_outlined,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                  const SizedBox(height: 8),
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
