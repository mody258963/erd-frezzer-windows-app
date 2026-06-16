import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/branch/branch_filter_scope.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/user_repository.dart';
import '../../di/injection.dart';
import '../shared/branch_dropdown.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel>? _items;
  String? _error;
  bool _loading = true;
  List<BranchModel> _branches = [];

  @override
  void initState() {
    super.initState();
    getIt<AppRefreshBus>().addListener(_onAppRefresh);
    _load();
    _loadBranches();
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

  Future<void> _loadBranches() async {
    try {
      final branches = await loadActiveBranches();
      if (mounted) setState(() => _branches = branches);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<UserRepository>().list(
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

  Future<void> _deactivate(UserModel user) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deactivateUser),
        content: Text(l10n.deactivateUserConfirm(user.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deactivateUser),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await getIt<UserRepository>().deactivate(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userDeactivated)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _showForm(BuildContext context, {UserModel? existing}) async {
    final l10n = context.l10n;
    final name = TextEditingController(text: existing?.name ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final password = TextEditingController();
    var role = existing?.role ?? UserRole.salesperson;
    String? branchId = existing?.branchId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final needsBranch =
              role == UserRole.salesperson || role == UserRole.warehouse;

          return AlertDialog(
            title: Text(existing == null ? l10n.newUser : l10n.editUser),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...spacedFormFields([
                    TextField(
                      controller: name,
                      decoration: InputDecoration(labelText: l10n.name),
                    ),
                    TextField(
                      controller: email,
                      decoration: InputDecoration(labelText: l10n.email),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (existing == null)
                      TextField(
                        controller: password,
                        decoration: InputDecoration(labelText: l10n.password),
                        obscureText: true,
                      ),
                    DropdownButtonFormField<UserRole>(
                      value: role,
                      decoration: InputDecoration(labelText: l10n.role),
                      items: UserRole.values
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialog(() => role = v);
                      },
                    ),
                    if (needsBranch && _branches.isNotEmpty)
                      BranchDropdown(
                        branches: _branches,
                        value: branchId,
                        label: l10n.branch,
                        onChanged: (v) => setDialog(() => branchId = v),
                        validator: (v) =>
                            needsBranch && (v == null || v.isEmpty)
                                ? l10n.branchRequired
                                : null,
                      ),
                    ]),
                  ],
                ),
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
          );
        },
      ),
    );

    if (saved != true || !mounted) return;

    final body = <String, dynamic>{
      'name': name.text.trim(),
      'email': email.text.trim(),
      if (existing == null) 'password': password.text,
      'role': role.name,
      if (branchId != null && branchId!.isNotEmpty) 'branch_id': branchId,
    };

    try {
      if (existing == null) {
        await getIt<UserRepository>().create(body);
      } else {
        body.remove('password');
        await getIt<UserRepository>().update(existing.id, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userSaved)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    name.dispose();
    email.dispose();
    password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.usersTitle,
          subtitle: l10n.usersSubtitle,
          actions: [
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.settingsTitle),
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            FilledButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.person_add),
              label: Text(l10n.newUser),
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
                        final u = _items![i];
                        return EntityListTile(
                          title: u.name,
                          subtitle:
                              '${u.email} · ${u.role.name}${u.branchName != null ? ' · ${u.branchName}' : ''}',
                          leading: CircleAvatar(
                            child: Text(
                              u.name.isNotEmpty
                                  ? u.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          trailing: u.isActive
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () =>
                                          _showForm(context, existing: u),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.person_off_outlined),
                                      onPressed: () => _deactivate(u),
                                    ),
                                  ],
                                )
                              : Chip(label: Text(l10n.inactive)),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
