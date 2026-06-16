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
import '../../data/models/supplier_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../di/injection.dart';
import '../customers/widgets/linked_balance_card.dart';
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
    final l10n = context.l10n;
    double debt = s.outstandingBalance;
    LinkedBalanceModel? linkedBalance;
    SupplierModel supplier = s;
    try {
      supplier = await getIt<SupplierRepository>().get(s.id);
      debt = await getIt<SupplierRepository>().debt(s.id);
      try {
        linkedBalance = await getIt<SupplierRepository>().linkedBalance(s.id);
      } catch (_) {}
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }
    if (!context.mounted) return;

    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canEdit = RolePermissions.canPerform(AppAction.supplierCreate, role);
    final canDelete = RolePermissions.canPerform(AppAction.supplierDelete, role);

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EntityProfileHeader(
                  title: s.name,
                  subtitle: s.contactPerson,
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(ctx).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: Theme.of(ctx).colorScheme.onPrimaryContainer,
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
                    color: (debt > 0 ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (debt > 0 ? AppColors.warning : AppColors.success)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: debt > 0 ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.supplierDebt,
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                            Text(
                              formatMoney(ctx, debt),
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (linkedBalance != null && linkedBalance.isLinked) ...[
                  const SizedBox(height: 12),
                  LinkedBalanceCard(
                    linkedBalance: linkedBalance,
                    showSupplierLink: false,
                    onOpenCustomer: supplier.linkedCustomerId != null
                        ? () {
                            Navigator.pop(ctx);
                            context.push('/customers/${supplier.linkedCustomerId}');
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.close),
                    ),
                    if (canEdit)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showForm(context, supplier: s);
                        },
                        child: Text(l10n.edit),
                      ),
                    if (canDelete)
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _delete(context, s.id);
                        },
                        child: Text(
                          l10n.delete,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
