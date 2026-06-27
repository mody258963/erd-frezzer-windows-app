import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/logging/app_logger.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/sale_quantity.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/transfer_repository.dart';
import '../../di/injection.dart';
import '../shared/branch_dropdown.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/part_dropdown.dart';
import '../shared/status_chip.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  List<Map<String, dynamic>>? _items;
  Map<String, String> _branchNames = {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadBranchNames() async {
    try {
      final branches = await loadActiveBranches();
      _branchNames = branchNameById(branches);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadBranchNames();
      final items = await getIt<TransferRepository>().list();
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

  String _transferSubtitle(Map<String, dynamic> t) {
    final from = resolveBranchName(
      _branchNames,
      t['from_branch_id'],
      row: t,
      branchKey: 'from_branch',
    );
    final to = resolveBranchName(
      _branchNames,
      t['to_branch_id'],
      row: t,
      branchKey: 'to_branch',
    );
    return context.l10n.transferBranches(from, to);
  }

  Future<void> _completeTransfer(BuildContext context, String id) async {
    final l10n = context.l10n;
    var valuation = 'cost';
    var recordBranchCharge = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.completeTransfer),
          titlePadding: kDialogTitlePadding,
          contentPadding: kDialogContentPadding,
          actionsPadding: kDialogActionsPadding,
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.completeTransferHint,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: valuation,
                  decoration: InputDecoration(
                    labelText: l10n.transferValuation,
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'cost',
                      child: Text(l10n.valuationCost),
                    ),
                    DropdownMenuItem(
                      value: 'sell',
                      child: Text(l10n.valuationSell),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => valuation = v);
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.recordInterBranchCharge),
                  subtitle: Text(l10n.recordBranchChargeHint),
                  value: recordBranchCharge,
                  onChanged: (v) {
                    setS(() => recordBranchCharge = v ?? true);
                  },
                ),
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
              child: Text(l10n.completeTransfer),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      await getIt<TransferRepository>().complete(
        id,
        valuation: valuation,
        recordBranchCharge: recordBranchCharge,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recordBranchCharge
                ? l10n.transferCompletedWithCharge
                : l10n.transferCompleted,
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.transferCreate, role)) return;

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

    if (branches.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noData)),
      );
      return;
    }

    if (!mounted) return;

    final userBranchId = context.read<AuthCubit>().state.user?.branchId;
    var fromBranchId = userBranchId ?? branches.first.id;
    if (!branches.any((b) => b.id == fromBranchId)) {
      fromBranchId = branches.first.id;
    }
    var toBranchId = branches
        .firstWhere((b) => b.id != fromBranchId, orElse: () => branches.last)
        .id;

    final result = await showDialog<
        ({
          String from,
          String to,
          List<({String partId, double qty, double? unitCost})> items,
        })?>(
      context: context,
      builder: (ctx) => _TransferFormDialog(
        branches: branches,
        fromBranchId: fromBranchId,
        toBranchId: toBranchId,
      ),
    );

    if (result == null) return;

    try {
      await getIt<TransferRepository>().create({
        'from_branch_id': result.from,
        'to_branch_id': result.to,
        'items': [
          for (final item in result.items)
            {
              'part_id': item.partId,
              'quantity': item.qty,
              if (item.unitCost != null) 'unit_cost': item.unitCost,
            },
        ],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transferSaved)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _reverseTransfer(BuildContext context, String id) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.transferReverse, role)) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reverseTransferTitle),
        titlePadding: kDialogTitlePadding,
        contentPadding: kDialogContentPadding,
        actionsPadding: kDialogActionsPadding,
        content: Text(
          l10n.reverseTransferHint,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.reverseTransfer),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await getIt<TransferRepository>().reverse(id);
      if (!context.mounted) return;
      getIt<AppRefreshBus>().notify(AppRefreshKind.inventory);
      getIt<AppRefreshBus>().notify(AppRefreshKind.catalog);
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transferReversed)),
      );
      await _load();
    } on DioException catch (e) {
      if (!context.mounted) return;
      final msg = AppLogger.apiResponseMessage(e) ?? AppLogger.dioMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _editTransfer(BuildContext context, String id) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.transferEdit, role)) return;

    Map<String, dynamic> transfer;
    try {
      transfer = await getIt<TransferRepository>().get(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }

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

    if (!mounted) return;

    if ((transfer['status'] as String? ?? '') != 'pending') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transferEditPendingOnly)),
      );
      return;
    }

    final fromBranchId = transfer['from_branch_id'] as String? ?? '';
    final toBranchId = transfer['to_branch_id'] as String? ?? '';
    final initialLines = _linesFromTransfer(transfer);
    final initialNotes = transfer['notes'] as String?;
    if (initialLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noData)),
      );
      return;
    }

    final result = await showDialog<
        ({
          List<({String partId, double qty, double? unitCost})> items,
          String? notes,
        })?>(
      context: context,
      builder: (ctx) => _TransferFormDialog(
        branches: branches,
        fromBranchId: fromBranchId,
        toBranchId: toBranchId,
        initialLines: initialLines,
        initialNotes: initialNotes,
        isEdit: true,
      ),
    );

    if (result == null) return;

    try {
      await getIt<TransferRepository>().update(id, {
        if (result.notes != null) 'notes': result.notes,
        'items': [
          for (final item in result.items)
            {
              'part_id': item.partId,
              'quantity': item.qty,
              if (item.unitCost != null) 'unit_cost': item.unitCost,
            },
        ],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transferUpdated)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<_TransferLineDraft> _linesFromTransfer(Map<String, dynamic> transfer) {
    final items = transfer['items'] as List<dynamic>? ?? [];
    final lines = <_TransferLineDraft>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final part = item['part'] as Map<String, dynamic>?;
      final partId = item['part_id'] as String? ?? '';
      if (partId.isEmpty) continue;
      final code = part?['code'] as String? ?? '';
      final name = part?['name'] as String? ?? '';
      final label = code.isNotEmpty || name.isNotEmpty
          ? '$code — $name'
          : partId;
      lines.add(
        _TransferLineDraft(
          partId: partId,
          label: label,
          unit: part?['unit'] as String?,
          unitLabel: part?['unit_label'] as String?,
          quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
          unitCost: (item['unit_cost'] as num?)?.toDouble(),
        ),
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.transferCreate, role);
    final canCancel = RolePermissions.canPerform(AppAction.transferCancel, role);
    final canEdit = RolePermissions.canPerform(AppAction.transferEdit, role);
    final canReverse = RolePermissions.canPerform(AppAction.transferReverse, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.transfersTitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: Text(l10n.newAction),
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
                        final t = _items![i];
                        final id = t['id'] as String;
                        final status = t['status'] as String? ?? '';
                        final shortId =
                            id.length > 8 ? '${id.substring(0, 8)}…' : id;
                        return EntityListTile(
                          title: l10n.transferRowTitle(shortId),
                          subtitle: _transferSubtitle(t),
                          leading: const Icon(Icons.swap_horiz),
                          trailing: status == 'pending'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canEdit)
                                      IconButton(
                                        tooltip: l10n.editTransfer,
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _editTransfer(
                                          context,
                                          id,
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: l10n.completeTransfer,
                                      icon: const Icon(Icons.check_circle_outline),
                                      onPressed: () => _completeTransfer(
                                        context,
                                        id,
                                      ),
                                    ),
                                    if (canCancel)
                                      IconButton(
                                        tooltip: l10n.cancelTransfer,
                                        icon: const Icon(Icons.cancel_outlined),
                                        onPressed: () async {
                                          await getIt<TransferRepository>()
                                              .cancel(id);
                                          await _load();
                                        },
                                      ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status == 'completed' && canReverse)
                                      IconButton(
                                        tooltip: l10n.reverseTransfer,
                                        icon: const Icon(Icons.undo_outlined),
                                        onPressed: () => _reverseTransfer(
                                          context,
                                          id,
                                        ),
                                      ),
                                    StatusChip(
                                      label: localizeApiStatus(context, status),
                                      variant: status == 'completed'
                                          ? StatusChipVariant.success
                                          : status == 'reversed'
                                              ? StatusChipVariant.warning
                                              : StatusChipVariant.warning,
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _TransferLineDraft {
  _TransferLineDraft({
    required this.partId,
    required this.label,
    this.availableQty,
    this.unit,
    this.unitLabel,
    this.quantity = 1,
    this.unitCost,
  });

  final String partId;
  final String label;
  double? availableQty;
  final String? unit;
  final String? unitLabel;
  double quantity;
  double? unitCost;
}

class _TransferFormDialog extends StatefulWidget {
  const _TransferFormDialog({
    required this.branches,
    required this.fromBranchId,
    required this.toBranchId,
    this.initialLines,
    this.initialNotes,
    this.isEdit = false,
  });

  final List<BranchModel> branches;
  final String fromBranchId;
  final String toBranchId;
  final List<_TransferLineDraft>? initialLines;
  final String? initialNotes;
  final bool isEdit;

  @override
  State<_TransferFormDialog> createState() => _TransferFormDialogState();
}

class _TransferFormDialogState extends State<_TransferFormDialog> {
  late String _fromBranchId;
  late String _toBranchId;
  List<PartPickOption> _partOptions = [];
  bool _loadingParts = false;
  final _lines = <_TransferLineDraft>[];
  final _qtyControllers = <TextEditingController>[];
  final _unitCostControllers = <TextEditingController>[];
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _fromBranchId = widget.fromBranchId;
    _toBranchId = widget.toBranchId;
    _notes = TextEditingController(text: widget.initialNotes ?? '');
    if (widget.initialLines != null) {
      _populateLines(widget.initialLines!);
      _loadParts(preserveLines: true);
    } else {
      _loadParts();
    }
  }

  void _populateLines(List<_TransferLineDraft> lines) {
    for (final line in lines) {
      _lines.add(line);
      _qtyControllers.add(
        TextEditingController(
          text: formatSaleQuantity(line.quantity, unit: line.unit),
        ),
      );
      _unitCostControllers.add(
        TextEditingController(
          text: line.unitCost != null
              ? line.unitCost!.toStringAsFixed(2)
              : '',
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers) {
      c.dispose();
    }
    for (final c in _unitCostControllers) {
      c.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadParts({bool preserveLines = false}) async {
    if (!preserveLines) {
      setState(() {
        _loadingParts = true;
        _lines.clear();
        for (final c in _qtyControllers) {
          c.dispose();
        }
        _qtyControllers.clear();
        for (final c in _unitCostControllers) {
          c.dispose();
        }
        _unitCostControllers.clear();
      });
    } else {
      setState(() => _loadingParts = true);
    }
    try {
      final options = await loadPartsForBranchTransfer(_fromBranchId);
      if (!mounted) return;
      setState(() {
        _partOptions = options;
        _loadingParts = false;
        if (preserveLines) {
          _mergeAvailableQtyFromOptions();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingParts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.failedLoadParts}: $e')),
      );
    }
  }

  void _mergeAvailableQtyFromOptions() {
    for (final line in _lines) {
      for (final option in _partOptions) {
        if (option.partId != line.partId) continue;
        line.availableQty = option.availableQty;
        break;
      }
    }
  }

  void _addPart(PartPickOption option) {
    final step = saleQuantityStep(option.unit);
    final existing = _lines.indexWhere((l) => l.partId == option.partId);
    if (existing >= 0) {
      setState(() {
        _lines[existing].quantity = normalizeSaleQuantity(
          _lines[existing].quantity + step,
          _lines[existing].unit,
        );
        _qtyControllers[existing].text = formatSaleQuantity(
          _lines[existing].quantity,
          unit: _lines[existing].unit,
        );
      });
      return;
    }
    final qty = defaultSaleQuantity(option.unit);
    final line = _TransferLineDraft(
      partId: option.partId,
      label: option.label,
      availableQty: option.availableQty,
      unit: option.unit,
      unitLabel: option.unitLabel,
      quantity: qty,
      unitCost: option.defaultUnitCost,
    );
    setState(() {
      _lines.add(line);
      _qtyControllers.add(
        TextEditingController(
          text: formatSaleQuantity(qty, unit: option.unit),
        ),
      );
      _unitCostControllers.add(
        TextEditingController(
          text: option.defaultUnitCost != null
              ? option.defaultUnitCost!.toStringAsFixed(2)
              : '',
        ),
      );
    });
  }

  void _removeLine(int index) {
    setState(() {
      _qtyControllers[index].dispose();
      _unitCostControllers[index].dispose();
      _qtyControllers.removeAt(index);
      _unitCostControllers.removeAt(index);
      _lines.removeAt(index);
    });
  }

  void _submit() {
    final l10n = context.l10n;
    if (!widget.isEdit && _fromBranchId == _toBranchId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.branchesMustDiffer)),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneLine)),
      );
      return;
    }

    final items = <({String partId, double qty, double? unitCost})>[];
    for (var i = 0; i < _lines.length; i++) {
      final raw =
          double.tryParse(_qtyControllers[i].text.replaceAll(',', '')) ?? 0;
      final line = _lines[i];
      final qty = normalizeSaleQuantity(raw, line.unit);
      if (isSaleQuantityTooLow(qty, line.unit)) continue;
      if (!widget.isEdit &&
          line.availableQty != null &&
          !hasEnoughStock(qty, line.availableQty!)) {
        final unitLabel = line.unit != null
            ? localizePartUnitLabel(
                context,
                line.unit!,
                line.unitLabel ?? '',
              )
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              unitLabel.isEmpty
                  ? l10n.maxQtyAvailable(
                      formatSaleQuantity(line.availableQty!, unit: line.unit),
                    )
                  : '${l10n.maxQtyAvailable(formatSaleQuantity(line.availableQty!, unit: line.unit))} $unitLabel',
            ),
          ),
        );
        return;
      }
      double? unitCost;
      final costText = _unitCostControllers[i].text.trim();
      if (costText.isNotEmpty) {
        unitCost = double.tryParse(costText.replaceAll(',', ''));
        if (unitCost == null || unitCost < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.invalidAmount)),
          );
          return;
        }
      }
      items.add((partId: line.partId, qty: qty, unitCost: unitCost));
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneLine)),
      );
      return;
    }

    if (widget.isEdit) {
      final notesText = _notes.text.trim();
      Navigator.pop(
        context,
        (
          items: items,
          notes: notesText.isEmpty ? null : notesText,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      (from: _fromBranchId, to: _toBranchId, items: items),
    );
  }

  String _branchLabel(String branchId) {
    for (final b in widget.branches) {
      if (b.id == branchId) return b.name;
    }
    return branchId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.isEdit ? l10n.editTransfer : l10n.newTransfer),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: spacedFormFields([
              if (widget.isEdit) ...[
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.fromBranch),
                  child: Text(_branchLabel(_fromBranchId)),
                ),
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.toBranch),
                  child: Text(_branchLabel(_toBranchId)),
                ),
              ] else ...[
                BranchDropdown(
                  branches: widget.branches,
                  value: _fromBranchId,
                  label: l10n.fromBranch,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _fromBranchId = v);
                    _loadParts();
                  },
                ),
                BranchDropdown(
                  branches: widget.branches,
                  value: _toBranchId,
                  label: l10n.toBranch,
                  onChanged: (v) {
                    if (v != null) setState(() => _toBranchId = v);
                  },
                ),
              ],
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
                Autocomplete<PartPickOption>(
                  optionsBuilder: (query) {
                    final q = query.text.trim().toLowerCase();
                    if (q.isEmpty) return _partOptions.take(30);
                    return _partOptions
                        .where((p) => p.label.toLowerCase().contains(q))
                        .take(30);
                  },
                  displayStringForOption: (o) => o.label,
                  onSelected: _addPart,
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: l10n.searchScanBarcode,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 220,
                            maxWidth: 520,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  option.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: option.availableQty != null
                                    ? Text(
                                        '${l10n.available}: ${formatSaleQuantity(option.availableQty!, unit: option.unit)}'
                                        '${option.unit != null ? ' ${localizePartUnitLabel(context, option.unit!, option.unitLabel ?? '')}' : ''}',
                                      )
                                    : null,
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (_lines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.lineItems,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _lines.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lines[i].label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                ),
                                if (_lines[i].availableQty != null)
                                  Text(
                                    '${l10n.available}: ${formatSaleQuantity(_lines[i].availableQty!, unit: _lines[i].unit)}'
                                    '${_lines[i].unit != null ? ' ${localizePartUnitLabel(context, _lines[i].unit!, _lines[i].unitLabel ?? '')}' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _qtyControllers[i],
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: l10n.qty,
                                helperText: _lines[i].unit != null
                                    ? localizePartUnitLabel(
                                        context,
                                        _lines[i].unit!,
                                        _lines[i].unitLabel ?? '',
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: isFractionalSaleUnit(_lines[i].unit),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _unitCostControllers[i],
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: l10n.unitCost,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeLine(i),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (widget.isEdit) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  decoration: InputDecoration(labelText: l10n.notes),
                  maxLines: 2,
                ),
              ],
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
          onPressed: _loadingParts ||
                  (!widget.isEdit && _partOptions.isEmpty) ||
                  (widget.isEdit && _lines.isEmpty)
              ? null
              : _submit,
          child: Text(widget.isEdit ? l10n.save : l10n.create),
        ),
      ],
    );
  }
}
