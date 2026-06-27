import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/branch/branch_filter_cubit.dart';
import '../../core/branch/branch_filter_scope.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/linked_balance_model.dart';
import '../../data/models/supplier_installment_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/installment_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../customers/widgets/linked_balance_card.dart';
import '../installments/pay_installment_dialog.dart';
import 'pay_supplier_dialog.dart';
import '../shared/entity_detail_widgets.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<SupplierModel>? _items;
  String? _error;
  bool _loading = true;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<SupplierRepository>().list(
        branchId: apiBranchIdFromContext(context),
      );
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showDetail(BuildContext context, SupplierModel s) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _SupplierDetailDialog(
        supplier: s,
        onEdit: (supplier) {
          Navigator.pop(ctx);
          _showForm(context, supplier: supplier);
        },
        onDelete: (id) async {
          Navigator.pop(ctx);
          await _delete(context, id);
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final l10n = context.l10n;
    try {
      await getIt<SupplierRepository>().delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supplierDeleted)),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showForm(
    BuildContext context, {
    SupplierModel? supplier,
  }) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.supplierCreate, role)) return;

    final isEdit = supplier != null;
    if (!isEdit) {
      final branchId = requiredBranchIdFromContext(context);
      if (branchId == null || branchId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supplierBranchRequired)),
        );
        return;
      }
    }

    String? branchLabel;
    if (!isEdit) {
      final branchId = requiredBranchIdFromContext(context)!;
      final user = context.read<AuthCubit>().state.user;
      branchLabel = context.read<BranchFilterCubit>().state.branchNameFor(branchId) ??
          user?.branchName ??
          branchId;
    }

    final name = TextEditingController(text: supplier?.name ?? '');
    final contactPerson =
        TextEditingController(text: supplier?.contactPerson ?? '');
    final phone = TextEditingController(text: supplier?.phone ?? '');
    final email = TextEditingController(text: supplier?.email ?? '');
    final address = TextEditingController(text: supplier?.address ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? l10n.editSupplier : l10n.newSupplier),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: spacedFormFields([
              if (!isEdit &&
                  branchLabel != null &&
                  branchLabel.isNotEmpty)
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.branch),
                  child: Text(branchLabel),
                ),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.supplierName),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: contactPerson,
                decoration: InputDecoration(labelText: l10n.contactPerson),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: l10n.phoneNumber),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: l10n.supplierEmail),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: address,
                decoration: InputDecoration(labelText: l10n.supplierAddress),
                textInputAction: TextInputAction.done,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (ok != true) {
      name.dispose();
      contactPerson.dispose();
      phone.dispose();
      email.dispose();
      address.dispose();
      return;
    }

    if (name.text.trim().isEmpty) {
      name.dispose();
      contactPerson.dispose();
      phone.dispose();
      email.dispose();
      address.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.nameRequired)),
        );
      }
      return;
    }

    final body = {
      'name': name.text.trim(),
      'contact_person': contactPerson.text.trim(),
      'phone': phone.text.trim(),
      'email': email.text.trim(),
      'address': address.text.trim(),
    };

    name.dispose();
    contactPerson.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();

    try {
      final repo = getIt<SupplierRepository>();
      if (isEdit) {
        await repo.update(supplier.id, body);
      } else {
        await repo.create(
          body,
          branchId: requiredBranchIdFromContext(context),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supplierSaved)),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.supplierCreate, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.suppliersTitle,
          subtitle: l10n.suppliersSubtitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.newSupplier),
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
                      emptyMessage: apiBranchIdFromContext(context) != null
                          ? l10n.supplierBranchPoHint
                          : l10n.noData,
                      itemBuilder: (context, i) {
                        final s = _items![i];
                        final subtitleParts = <String>[
                          if (s.contactPerson?.trim().isNotEmpty == true)
                            s.contactPerson!,
                          if (s.phone?.trim().isNotEmpty == true) s.phone!,
                        ];
                        return EntityListTile(
                          title: s.name,
                          subtitle: subtitleParts.join(' · '),
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          trailing: s.outstandingBalance > 0
                              ? Chip(
                                  label: Text(
                                    formatMoney(context, s.outstandingBalance),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor:
                                      AppColors.warning.withValues(alpha: 0.15),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => _showDetail(context, s),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _SupplierDetailDialog extends StatefulWidget {
  const _SupplierDetailDialog({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  final SupplierModel supplier;
  final void Function(SupplierModel supplier) onEdit;
  final Future<void> Function(String id) onDelete;

  @override
  State<_SupplierDetailDialog> createState() => _SupplierDetailDialogState();
}

class _SupplierDetailDialogState extends State<_SupplierDetailDialog> {
  late SupplierModel _supplier;
  double _debt = 0;
  LinkedBalanceModel? _linkedBalance;
  List<SupplierInstallmentModel> _installments = [];
  bool _loading = true;
  String? _payingId;

  @override
  void initState() {
    super.initState();
    _supplier = widget.supplier;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = getIt<SupplierRepository>();
      final supplier = await repo.get(widget.supplier.id);
      final debt = await repo.debt(widget.supplier.id);
      LinkedBalanceModel? linkedBalance;
      try {
        linkedBalance = await repo.linkedBalance(widget.supplier.id);
      } catch (_) {}
      List<SupplierInstallmentModel> installments = [];
      try {
        installments = await getIt<InstallmentRepository>()
            .listForSupplier(widget.supplier.id);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _supplier = supplier;
        _debt = debt;
        _linkedBalance = linkedBalance;
        _installments = installments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _paySupplierLumpSum() async {
    final l10n = context.l10n;
    if (_debt <= 0) return;

    final result = await PaySupplierDialog.show(
      context,
      supplierName: _supplier.name,
      totalDebt: _debt,
    );
    if (result == null || !mounted) return;

    setState(() => _payingId = _supplier.id);
    try {
      await getIt<SupplierRepository>().recordPayment(
        _supplier.id,
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
      await _load();
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
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
      if (mounted) setState(() => _payingId = null);
    }
  }

  Future<void> _payInstallment(SupplierInstallmentModel inst) async {
    final l10n = context.l10n;
    if (!inst.canPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.installmentAlreadyPaid)),
      );
      return;
    }

    final result = await PayInstallmentDialog.show(context, inst);
    if (result == null || !mounted) return;

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
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 422) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.installmentAlreadyPaid)),
        );
        await _load();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _payingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = _supplier;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canEdit = RolePermissions.canPerform(AppAction.supplierCreate, role);
    final canDelete = RolePermissions.canPerform(AppAction.supplierDelete, role);
    final canPay = RolePermissions.canPerform(AppAction.installmentPay, role);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EntityProfileHeader(
                              title: s.name,
                              subtitle: s.contactPerson,
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              chips: [
                                Chip(
                                  label: Text(s.isActive ? l10n.active : l10n.inactive),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: (_debt > 0 ? AppColors.warning : AppColors.success)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (_debt > 0
                                          ? AppColors.warning
                                          : AppColors.success)
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    color: _debt > 0
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.supplierDebt,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        Text(
                                          formatMoney(context, _debt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canPay && _debt > 0)
                                    FilledButton(
                                      onPressed: _payingId == _supplier.id
                                          ? null
                                          : _paySupplierLumpSum,
                                      child: _payingId == _supplier.id
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(l10n.pay),
                                    ),
                                ],
                              ),
                            ),
                            if (_installments.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              DetailSectionCard(
                                title: l10n.supplierUnpaidInstallments,
                                child: Column(
                                  children: [
                                    for (final inst in _installments)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    formatMoney(
                                                      context,
                                                      inst.remainingBalance,
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall,
                                                  ),
                                                  Text(
                                                    [
                                                      if (inst.installmentNo > 0)
                                                        '#${inst.installmentNo}',
                                                      l10n.dueDate(inst.dueDate ?? '—'),
                                                    ].join(' · '),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (canPay && inst.canPay)
                                              TextButton(
                                                onPressed: _payingId == inst.id
                                                    ? null
                                                    : () => _payInstallment(inst),
                                                child: _payingId == inst.id
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text(l10n.payInstallmentLegacy),
                                              ),
                                          ],
                                        ),
                                      ),
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          context.push(
                                            '${RoutePaths.suppliers}?tab=payables',
                                          );
                                        },
                                        child: Text(l10n.viewAllInstallments),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_linkedBalance != null && _linkedBalance!.isLinked) ...[
                              const SizedBox(height: 12),
                              LinkedBalanceCard(
                                linkedBalance: _linkedBalance!,
                                showSupplierLink: false,
                                onOpenCustomer: _supplier.linkedCustomerId != null
                                    ? () {
                                        Navigator.pop(context);
                                        context.push(
                                          '/customers/${_supplier.linkedCustomerId}',
                                        );
                                      }
                                    : null,
                              ),
                            ],
                            const SizedBox(height: 12),
                            DetailSectionCard(
                              title: l10n.contactInfo,
                              child: Column(
                                children: [
                                  DetailField(
                                    icon: Icons.person_outline,
                                    label: l10n.contactPerson,
                                    value: s.contactPerson ?? '—',
                                  ),
                                  DetailField(
                                    icon: Icons.phone_outlined,
                                    label: l10n.phoneNumber,
                                    value: s.phone ?? '—',
                                  ),
                                  DetailField(
                                    icon: Icons.email_outlined,
                                    label: l10n.supplierEmail,
                                    value: s.email ?? '—',
                                  ),
                                  DetailField(
                                    icon: Icons.location_on_outlined,
                                    label: l10n.supplierAddress,
                                    value: s.address ?? '—',
                                  ),
                                  if (s.notes?.trim().isNotEmpty == true)
                                    DetailField(
                                      icon: Icons.notes_outlined,
                                      label: l10n.description,
                                      value: s.notes!,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.close),
                        ),
                        if (canEdit)
                          TextButton(
                            onPressed: () => widget.onEdit(s),
                            child: Text(l10n.edit),
                          ),
                        if (canDelete)
                          TextButton(
                            onPressed: () => widget.onDelete(s.id),
                            child: Text(
                              l10n.delete,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
