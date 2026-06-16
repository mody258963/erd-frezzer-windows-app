import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/supplier_installment_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/installment_repository.dart';
import '../../di/injection.dart';
import '../../core/events/app_refresh_bus.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/status_chip.dart';
import 'pay_installment_dialog.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  List<SupplierInstallmentModel>? _items;
  String? _error;
  bool _loading = true;
  bool _overdueOnly = false;
  String? _payingId;

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
    if (!mounted || kind != AppRefreshKind.branchFilter) return;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = getIt<InstallmentRepository>();
      final items = _overdueOnly ? await repo.overdue() : await repo.list();
      for (final inst in items) {
        AppLogger.action('installments.row', {
          'id': inst.id,
          'isPaid': inst.isPaid,
          'amount': inst.amount,
          'amountPaid': inst.amountPaid,
          'balanceDue': inst.remainingBalance,
        });
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.error('installments.load.failed', e, st);
      if (!mounted) return;
      setState(() {
        _error = e is DioException ? AppLogger.dioMessage(e) : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _payInstallment(SupplierInstallmentModel inst) async {
    final l10n = context.l10n;
    if (!inst.canPay) {
      AppLogger.warning('installments.pay.skip.alreadyPaid');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.installmentAlreadyPaid)),
      );
      return;
    }

    final result = await PayInstallmentDialog.show(context, inst);
    if (result == null || !mounted) return;

    AppLogger.action('installments.pay.submit', {
      'id': inst.id,
      'payFullBalance': result.payFullBalance,
      'amount': result.amount,
    });

    setState(() => _payingId = inst.id);
    try {
      await getIt<InstallmentRepository>().pay(
        inst.id,
        paymentMethod: result.paymentMethod,
        amount: result.payFullBalance ? null : result.amount,
        notes: result.notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.installmentPaidSuccess),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await _load();
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
    } on DioException catch (e, st) {
      AppLogger.error('installments.pay.failed', e, st);
      if (!mounted) return;
      if (e.response?.statusCode == 422 &&
          AppLogger.apiResponseMessageContains(e, 'already paid')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.installmentAlreadyPaid)),
        );
        await _load();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLogger.dioMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _payingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canPay = RolePermissions.canPerform(AppAction.installmentPay, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.installmentsTitle,
          actions: [
            FilterChip(
              label: Text(l10n.overdue),
              selected: _overdueOnly,
              onSelected: (v) {
                setState(() => _overdueOnly = v);
                _load();
              },
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
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
                        final inst = _items![i];
                        final isBusy = _payingId == inst.id;
                        final poLabel = inst.purchaseOrderId != null &&
                                inst.purchaseOrderId!.length > 8
                            ? inst.purchaseOrderId!.substring(0, 8)
                            : inst.purchaseOrderId;
                        final balance = inst.remainingBalance;
                        final titleMoney = inst.isPaid
                            ? formatMoney(context, inst.amount)
                            : formatMoney(context, balance);
                        final subtitleParts = <String>[
                          if (inst.supplierName != null) inst.supplierName!,
                          if (poLabel != null) '${l10n.purchaseOrder} $poLabel',
                          if (inst.installmentNo > 0)
                            '#${inst.installmentNo}',
                          l10n.dueDate(inst.dueDate ?? '—'),
                          if (!inst.isPaid && inst.amountPaid > 0)
                            '${l10n.installmentAlreadyPaidAmount}: ${formatMoney(context, inst.amountPaid)}',
                        ];
                        return EntityListTile(
                          title: titleMoney,
                          subtitle: subtitleParts.join(' · '),
                          leading: const Icon(Icons.payments_outlined),
                          trailing: inst.isPaid
                              ? StatusChip(
                                  label: l10n.statusPaid,
                                  variant: StatusChipVariant.success,
                                )
                              : canPay && inst.canPay
                                  ? FilledButton(
                                      onPressed: isBusy
                                          ? null
                                          : () => _payInstallment(inst),
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
                                  : StatusChip(
                                      label: localizeApiStatus(
                                        context,
                                        inst.status,
                                      ),
                                      variant: StatusChipVariant.warning,
                                    ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
