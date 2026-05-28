import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_cubit.dart';

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
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<PartRepository>().list(search: _search.text);
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
                onPressed: () => _showForm(context),
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
                        final online =
                            context.watch<ConnectivityCubit>().state.isOnline;
                        return EntityListTile(
                          title: '${p.code} — ${p.name}',
                          subtitle: l10n.partRowSubtitle(
                            '${p.categoryDisplay} · ${localizePartUnitLabel(context, p.unit ?? '', p.unitLabel ?? p.unit ?? '')}',
                            formatMoney(context, p.sellPrice),
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
                          trailing: canCreate
                              ? IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showForm(context, part: p),
                                )
                              : const Icon(Icons.chevron_left),
                          onTap: () {
                            if (!online) {
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

    final result = await showDialog<PartFormResult>(
      context: context,
      builder: (ctx) => PartFormDialog(
        isEdit: isEdit,
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

    final body = {
      'code': result.code,
      'name': result.name,
      'category_key': result.categoryKey,
      'unit': result.unit,
      'sell_price': result.sellPrice,
      'cost_price': result.costPrice,
      'min_stock': result.minStock,
      'is_active': true,
    };

    try {
      final repo = getIt<PartRepository>();
      PartModel saved;
      if (isEdit) {
        saved = await repo.update(part.id, body);
      } else {
        saved = await repo.create(body);
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
