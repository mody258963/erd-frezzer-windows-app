import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/branch_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/status_chip.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<BranchModel>? _items;
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
      final items = await getIt<BranchRepository>().list();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.branchCreate, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.branchesTitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.newBranch),
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
                        final b = _items![i];
                        return EntityListTile(
                          title: b.name,
                          subtitle: b.address ?? '',
                          leading: CircleAvatar(
                            child: Icon(
                              b.isActive ? Icons.store : Icons.store_outlined,
                            ),
                          ),
                          trailing: !b.isActive
                              ? StatusChip(
                                  label: l10n.inactive,
                                  variant: StatusChipVariant.warning,
                                )
                              : null,
                          onTap: () => _showForm(context, branch: b),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _showForm(BuildContext context, {BranchModel? branch}) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final isEdit = branch != null;
    if (isEdit && !RolePermissions.canPerform(AppAction.branchCreate, role)) {
      return;
    }
    if (!isEdit && !RolePermissions.canPerform(AppAction.branchCreate, role)) {
      return;
    }

    final name = TextEditingController(text: branch?.name ?? '');
    final address = TextEditingController(text: branch?.address ?? '');
    final phone = TextEditingController(text: branch?.phone ?? '');
    var active = branch?.isActive ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? l10n.editBranch : l10n.newBranch),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spacedFormFields([
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.name),
                ),
                TextField(
                  controller: address,
                  decoration: InputDecoration(labelText: l10n.supplierAddress),
                ),
                TextField(
                  controller: phone,
                  decoration: InputDecoration(labelText: l10n.phoneNumber),
                ),
                CheckboxListTile(
                  value: active,
                  onChanged: (v) => setS(() => active = v ?? true),
                  title: Text(l10n.active),
                  contentPadding: EdgeInsets.zero,
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
      ),
    );

    if (ok != true) return;
    final body = {
      'name': name.text,
      'address': address.text,
      'phone': phone.text,
      'is_active': active,
    };
    final repo = getIt<BranchRepository>();
    if (isEdit) {
      await repo.update(branch!.id, body);
    } else {
      await repo.create(body);
    }
    await _load();
  }
}
