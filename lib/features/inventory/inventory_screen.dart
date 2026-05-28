import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../di/injection.dart';
import '../shared/branch_dropdown.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/part_dropdown.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<StockModel>? _items;
  Map<String, String> _branchNames = {};
  String? _error;
  bool _loading = true;
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadBranchNames() async {
    try {
      final branches = await loadActiveBranches();
      _branchNames = branchNameById(branches);
    } catch (_) {
      // List still works with ids if branches fail to load.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadBranchNames();
      final branchId = context.read<AuthCubit>().state.user?.branchId;
      List<StockModel> items;
      if (_lowStockOnly) {
        final alerts = await getIt<InventoryRepository>().lowStock();
        items = alerts
            .map(
              (a) => StockModel(
                partId: a['part_id'] as String? ?? '',
                branchId: a['branch_id'] as String? ?? '',
                quantity: (a['quantity'] as num?)?.toInt() ?? 0,
                branchName: resolveBranchName(
                  _branchNames,
                  a['branch_id'],
                  row: a,
                ),
              ),
            )
            .toList();
      } else if (branchId != null) {
        items = await getIt<InventoryRepository>().byBranch(branchId);
      } else {
        items = await getIt<InventoryRepository>().list();
      }
      items = items
          .map(
            (s) => StockModel(
              partId: s.partId,
              branchId: s.branchId,
              quantity: s.quantity,
              part: s.part,
              branchName: s.branchName ??
                  resolveBranchName(_branchNames, s.branchId),
            ),
          )
          .toList();
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

  String _branchLabel(StockModel s) {
    final name = s.branchName ??
        resolveBranchName(_branchNames, s.branchId);
    return context.l10n.branchRowLabel(name);
  }

  Future<void> _adjust() async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.inventoryAdjust, role)) return;

    List<BranchModel> branches;
    try {
      branches = await loadActiveBranches();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.failedLoadBranches}: $e')),
      );
      return;
    }

    if (branches.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noData)),
      );
      return;
    }

    if (!mounted) return;

    var selectedBranchId = context.read<AuthCubit>().state.user?.branchId;
    if (selectedBranchId == null ||
        !branches.any((b) => b.id == selectedBranchId)) {
      selectedBranchId = branches.first.id;
    }

    final result = await showDialog<
        ({String branchId, String partId, int delta, String reason})?>(
      context: context,
      builder: (ctx) => _AdjustStockDialog(
        branches: branches,
        initialBranchId: selectedBranchId!,
        initialReason: l10n.physicalCount,
      ),
    );

    if (result == null) return;

    try {
      await getIt<InventoryRepository>().adjust({
        'part_id': result.partId,
        'branch_id': result.branchId,
        'quantity_delta': result.delta,
        'reason': result.reason,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.stockAdjusted)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canAdjust = RolePermissions.canPerform(AppAction.inventoryAdjust, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.inventoryTitle,
          actions: [
            FilterChip(
              label: Text(l10n.lowStockFilter),
              selected: _lowStockOnly,
              onSelected: (v) {
                setState(() => _lowStockOnly = v);
                _load();
              },
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canAdjust)
              FilledButton.icon(
                onPressed: _adjust,
                icon: const Icon(Icons.tune),
                label: Text(l10n.adjust),
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
                        final part = s.part;
                        return EntityListTile(
                          title: part != null
                              ? '${part.code} — ${part.name}'
                              : s.partId,
                          subtitle: _branchLabel(s),
                          leading: const Icon(Icons.warehouse_outlined),
                          trailing: Text(
                            l10n.qtyRowLabel('${s.quantity}'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _AdjustStockDialog extends StatefulWidget {
  const _AdjustStockDialog({
    required this.branches,
    required this.initialBranchId,
    required this.initialReason,
  });

  final List<BranchModel> branches;
  final String initialBranchId;
  final String initialReason;

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  late String _branchId;
  String? _partId;
  List<PartPickOption> _partOptions = [];
  bool _loadingParts = false;
  final _delta = TextEditingController();
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    _branchId = widget.initialBranchId;
    _reason = TextEditingController(text: widget.initialReason);
    _loadParts();
  }

  @override
  void dispose() {
    _delta.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    setState(() {
      _loadingParts = true;
      _partId = null;
    });
    try {
      final options = await loadPartsForBranchAdjust(_branchId);
      if (!mounted) return;
      setState(() {
        _partOptions = options;
        _partId = options.isNotEmpty ? options.first.partId : null;
        _loadingParts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingParts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.failedLoadParts}: $e')),
      );
    }
  }

  void _submit() {
    final l10n = context.l10n;
    if (_partId == null || _partOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPartsAvailable)),
      );
      return;
    }
    final delta = int.tryParse(_delta.text);
    if (delta == null || delta == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quantityDelta)),
      );
      return;
    }
    Navigator.pop(
      context,
      (
        branchId: _branchId,
        partId: _partId!,
        delta: delta,
        reason: _reason.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.adjustStock),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: spacedFormFields([
              BranchDropdown(
                branches: widget.branches,
                value: _branchId,
                label: l10n.branch,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _branchId = v);
                  _loadParts();
                },
              ),
              if (_loadingParts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_partOptions.isEmpty)
                Text(
                  l10n.noPartsAvailable,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                PartDropdown(
                  options: _partOptions,
                  value: _partId,
                  label: l10n.selectPart,
                  onChanged: (v) => setState(() => _partId = v),
                ),
              TextField(
                controller: _delta,
                decoration: InputDecoration(labelText: l10n.quantityDelta),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _reason,
                decoration: InputDecoration(labelText: l10n.reason),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _loadingParts || _partOptions.isEmpty ? null : _submit,
          child: Text(l10n.adjust),
        ),
      ],
    );
  }
}
