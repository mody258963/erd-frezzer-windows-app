import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/part_category_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/part_category_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/loading_error.dart';
import '../shared/page_scaffold.dart';
import '../shared/status_chip.dart';

class PartCategoriesScreen extends StatefulWidget {
  const PartCategoriesScreen({super.key});

  @override
  State<PartCategoriesScreen> createState() => _PartCategoriesScreenState();
}

class _PartCategoriesScreenState extends State<PartCategoriesScreen> {
  List<PartCategoryModel>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final isOnline = context.read<ConnectivityCubit>().state.isOnline;
    if (!isOnline) {
      setState(() {
        _loading = false;
        _error = null;
        _items = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<PartCategoryRepository>().list(activeOnly: false);
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

  Future<void> _openAdd() async {
    final ok = await context.push<bool>(RoutePaths.partCategoryNew);
    if (ok == true) _load();
  }

  Future<void> _openEdit(PartCategoryModel category) async {
    final ok = await context.push<bool>(
      RoutePaths.partCategoryEdit(category.id),
      extra: category,
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOnline = context.watch<ConnectivityCubit>().state.isOnline;
    final role =
        context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canManage =
        RolePermissions.canPerform(AppAction.partCategoryManage, role);

    return PageScaffold(
      title: l10n.partCategoriesTitle,
      subtitle: l10n.partCategoriesSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOnline)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.cloud_off,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                title: Text(
                  l10n.internetRequired,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          if (!isOnline) const SizedBox(height: 12),
          Row(
            children: [
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              const Spacer(),
              if (canManage && isOnline)
                FilledButton.icon(
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addCategory),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: !isOnline
                ? Center(child: Text(l10n.internetRequired))
                : _loading
                    ? const LoadingView()
                    : _error != null
                        ? ErrorView(message: _error!, onRetry: _load)
                        : _items == null || _items!.isEmpty
                            ? Center(child: Text(l10n.noData))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: [
                                    DataColumn(label: Text(l10n.categoryName)),
                                    DataColumn(label: Text(l10n.categoryKey)),
                                    DataColumn(label: Text(l10n.sortOrder)),
                                    DataColumn(label: Text(l10n.categoryActive)),
                                  ],
                                  rows: _items!.map((c) {
                                    return DataRow(
                                      onSelectChanged: canManage
                                          ? (_) => _openEdit(c)
                                          : null,
                                      cells: [
                                        DataCell(Text(c.name)),
                                        DataCell(Text(c.key)),
                                        DataCell(Text('${c.sortOrder}')),
                                        DataCell(
                                          c.isActive
                                              ? StatusChip(
                                                  label: l10n.active,
                                                  variant: StatusChipVariant
                                                      .success,
                                                )
                                              : StatusChip(
                                                  label: l10n.inactive,
                                                  variant: StatusChipVariant
                                                      .warning,
                                                ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
          ),
        ],
      ),
    );
  }
}
