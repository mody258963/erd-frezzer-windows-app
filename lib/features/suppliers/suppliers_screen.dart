import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<SupplierRepository>().list();
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

  Future<void> _showDetail(BuildContext context, Map<String, dynamic> s) async {
    final l10n = context.l10n;
    final id = s['id'] as String;
    Map<String, dynamic> debt;
    try {
      debt = await getIt<SupplierRepository>().debt(id);
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
      builder: (ctx) => AlertDialog(
        title: Text(s['name'] as String? ?? ''),
        content: Text('${l10n.supplierDebt}: ${debt['outstanding_balance'] ?? debt}'),
        actions: [
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
                await _delete(context, id);
              },
              child: Text(l10n.delete),
            ),
        ],
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
    Map<String, dynamic>? supplier,
  }) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.supplierCreate, role)) return;

    final isEdit = supplier != null;
    final name = TextEditingController(text: supplier?['name'] as String? ?? '');
    final contactPerson =
        TextEditingController(text: supplier?['contact_person'] as String? ?? '');
    final phone = TextEditingController(text: supplier?['phone'] as String? ?? '');
    final address = TextEditingController(text: supplier?['address'] as String? ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? l10n.editSupplier : l10n.newSupplier),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.supplierName),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPerson,
                decoration: InputDecoration(labelText: l10n.contactPerson),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: l10n.phoneNumber),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: InputDecoration(labelText: l10n.supplierAddress),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
            ],
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
      address.dispose();
      return;
    }

    if (name.text.trim().isEmpty) {
      name.dispose();
      contactPerson.dispose();
      phone.dispose();
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
      'address': address.text.trim(),
    };

    name.dispose();
    contactPerson.dispose();
    phone.dispose();
    address.dispose();

    try {
      final repo = getIt<SupplierRepository>();
      if (isEdit) {
        await repo.update(supplier['id'] as String, body);
      } else {
        await repo.create(body);
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
                      emptyMessage: l10n.noData,
                      itemBuilder: (context, i) {
                        final s = _items![i];
                        return EntityListTile(
                              title: s['name'] as String? ?? '',
                              subtitle: [
                                if (s['contact_person'] != null &&
                                    '${s['contact_person']}'.isNotEmpty)
                                  '${s['contact_person']}',
                                if (s['phone'] != null &&
                                    '${s['phone']}'.isNotEmpty)
                                  '${s['phone']}',
                              ].join(' · '),
                              leading: const CircleAvatar(
                                child: Icon(Icons.local_shipping_outlined),
                              ),
                              onTap: () => _showDetail(context, s),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
