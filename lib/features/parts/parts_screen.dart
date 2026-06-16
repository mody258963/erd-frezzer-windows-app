import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/branch/branch_filter_cubit.dart';
import '../../core/branch/branch_filter_scope.dart';
import '../../core/catalog/catalog_refresh_scheduler.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/events/app_refresh_bus.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/part_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/part_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../../core/images/part_image_cache.dart';
import '../shared/entity_list_tile.dart';
import '../shared/part_network_image.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import 'part_form_dialog.dart';

class PartsScreen extends StatefulWidget {
  const PartsScreen({super.key});

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> {
  final _search = TextEditingController();
  List<PartModel>? _items;
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
    _search.dispose();
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
      final items = await getIt<PartRepository>().list(
        search: _search.text,
        branchId: requiredBranchIdFromContext(context),
      );
      setState(() {
        _items = items;
        _loading = false;
      });
      PartImageCache.prefetchAll(items.map((p) => p.imageUrl));
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
    final canCreate = RolePermissions.canPerform(AppAction.partCreate, role);
    final canDelete = RolePermissions.canPerform(AppAction.partDelete, role);
    final online = context.watch<ConnectivityCubit>().state.isOnline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.partsTitle,
          searchField: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: l10n.search,
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (_) => _load(),
          ),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: online ? () => _showForm(context) : null,
                icon: const Icon(Icons.add),
                label: Text(l10n.newPart),
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
                        final isOnline =
                            context.watch<ConnectivityCubit>().state.isOnline;
                        return EntityListTile(
                          title: '${p.code} — ${p.name}',
                          subtitle: l10n.partRowSubtitle(
                            '${p.categoryDisplay} · ${localizePartUnitLabel(context, p.unit ?? '', p.unitLabel ?? p.unit ?? '')}',
                            formatMoney(context, p.sellPrice),
                            formatMoney(context, p.costPrice),
                            '${p.minStock}',
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: PartNetworkImage(
                              imageUrl: p.imageUrl,
                              width: 40,
                              height: 40,
                            ),
                          ),
                          trailing: canCreate || canDelete
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canCreate)
                                      IconButton(
                                        tooltip: l10n.edit,
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: online
                                            ? () => _showForm(context, part: p)
                                            : null,
                                      ),
                                    if (canDelete)
                                      IconButton(
                                        tooltip: l10n.delete,
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        onPressed: online
                                            ? () => _deletePart(context, p)
                                            : null,
                                      ),
                                  ],
                                )
                              : const Icon(Icons.chevron_left),
                          onTap: () {
                            if (!isOnline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.partAnalysisOnlineOnly),
                                ),
                              );
                              return;
                            }
                            context.push(RoutePaths.partAnalysis(p.id));
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _showForm(BuildContext context, {PartModel? part}) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final isEdit = part != null;
    if (!RolePermissions.canPerform(AppAction.partCreate, role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partCreateNotAllowed)),
      );
      return;
    }

    if (!isEdit && !context.read<ConnectivityCubit>().state.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partAddOffline)),
      );
      return;
    }

    String? branchId;
    String? branchLabel;
    if (!isEdit) {
      branchId = requiredBranchIdFromContext(context);
      if (branchId == null || branchId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partBranchRequired)),
        );
        return;
      }
      final user = context.read<AuthCubit>().state.user;
      branchLabel = context.read<BranchFilterCubit>().state.branchNameFor(branchId) ??
          user?.branchName ??
          branchId;
    }

    final result = await showDialog<PartFormResult>(
      context: context,
      builder: (ctx) => PartFormDialog(
        isEdit: isEdit,
        branchLabel: branchLabel,
        initialCode: part?.code,
        initialName: part?.name,
        initialCategoryKey: part?.categoryKey,
        initialUnit: part?.unit,
        initialSellPrice: part?.sellPrice,
        initialCostPrice: part?.costPrice,
        initialMinStock: part?.minStock,
        initialImageUrl: part?.imageUrl,
      ),
    );
    if (result == null) return;

    final body = <String, dynamic>{
      'code': result.code,
      'name': result.name,
      'category_key': result.categoryKey,
      'unit': result.unit,
      'sell_price': result.sellPrice,
      'min_stock': result.minStock,
      'is_active': result.isActive,
    };
    if (!isEdit) {
      body['cost_price'] = result.costPrice;
      if (result.initialQuantity > 0) {
        body['initial_quantity'] = result.initialQuantity;
      }
    }

    try {
      final repo = getIt<PartRepository>();
      PartModel saved;
      if (isEdit) {
        saved = await repo.update(part.id, body);
      } else {
        saved = await repo.create(body, branchId: branchId);
      }

      final previousUrl = part?.imageUrl;
      if (result.removeImage) {
        try {
          await repo.deleteImage(saved.id);
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) rethrow;
        }
        await PartImageCache.evict(previousUrl);
      }
      if (result.pendingImagePath != null) {
        final updated =
            await repo.uploadImage(saved.id, result.pendingImagePath!);
        await PartImageCache.evict(previousUrl);
        await PartImageCache.prefetch(updated.imageUrl);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partSaved)),
      );
      getIt<AppRefreshBus>().notify(AppRefreshKind.catalog);
      getIt<AppRefreshBus>().notify(AppRefreshKind.inventory);
      if (getIt<ConnectivityCubit>().state.isOnline) {
        unawaited(getIt<CatalogRefreshScheduler>().refreshNow());
      }
      await _load();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_partErrorMessage(context, e))),
      );
    }
  }

  Future<void> _deletePart(BuildContext context, PartModel part) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.partDelete, role)) return;
    if (!context.read<ConnectivityCubit>().state.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partAddOffline)),
      );
      return;
    }

    final label = '${part.code} — ${part.name}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeletePart(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await getIt<PartRepository>().delete(part.id);
      await PartImageCache.evict(part.imageUrl);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partDeleted)),
      );
      getIt<AppRefreshBus>().notify(AppRefreshKind.catalog);
      getIt<AppRefreshBus>().notify(AppRefreshKind.inventory);
      unawaited(getIt<CatalogRefreshScheduler>().refreshNow());
      await _load();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_partErrorMessage(context, e))),
      );
    }
  }

  String _partErrorMessage(BuildContext context, Object e) {
    final l10n = context.l10n;
    final msg = e.toString().toLowerCase();
    if (msg.contains('branch_id') && msg.contains('required')) {
      return l10n.partBranchRequired;
    }
    if (msg.contains('unique') && msg.contains('code')) {
      return l10n.partCodeDuplicate;
    }
    if (msg.contains('unit') && msg.contains('invalid')) {
      return l10n.partInvalidUnit;
    }
    if (msg.contains('category')) {
      return l10n.partFillCategoryUnit;
    }
    return e.toString();
  }
}
