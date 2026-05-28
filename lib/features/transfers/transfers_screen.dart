import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
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

    final result = await showDialog<({String from, String to, String partId, int qty})?>(
      context: context,
      builder: (ctx) => _CreateTransferDialog(
        branches: branches,
        initialFromBranchId: fromBranchId,
        initialToBranchId: toBranchId,
      ),
    );

    if (result == null) return;

    try {
      await getIt<TransferRepository>().create({
        'from_branch_id': result.from,
        'to_branch_id': result.to,
        'items': [
          {'part_id': result.partId, 'quantity': result.qty},
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.transferCreate, role);
    final canCancel = RolePermissions.canPerform(AppAction.transferCancel, role);

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
                              : StatusChip(
                                  label: localizeApiStatus(context, status),
                                  variant: status == 'completed'
                                      ? StatusChipVariant.success
                                      : StatusChipVariant.warning,
                                ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _CreateTransferDialog extends StatefulWidget {
  const _CreateTransferDialog({
    required this.branches,
    required this.initialFromBranchId,
    required this.initialToBranchId,
  });

  final List<BranchModel> branches;
  final String initialFromBranchId;
  final String initialToBranchId;

  @override
  State<_CreateTransferDialog> createState() => _CreateTransferDialogState();
}

class _CreateTransferDialogState extends State<_CreateTransferDialog> {
  late String _fromBranchId;
  late String _toBranchId;
  String? _partId;
  List<PartPickOption> _partOptions = [];
  bool _loadingParts = false;
  final _qty = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _fromBranchId = widget.initialFromBranchId;
    _toBranchId = widget.initialToBranchId;
    _loadParts();
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    setState(() {
      _loadingParts = true;
      _partId = null;
    });
    try {
      final options = await loadPartsForBranchTransfer(_fromBranchId);
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
    if (_fromBranchId == _toBranchId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.branchesMustDiffer)),
      );
      return;
    }
    if (_partId == null || _partOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPartsAvailable)),
      );
      return;
    }
    final qty = int.tryParse(_qty.text) ?? 0;
    if (qty < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quantity)),
      );
      return;
    }
    final picked = _partOptions.firstWhere((p) => p.partId == _partId);
    if (picked.availableQty != null && qty > picked.availableQty!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maxQtyAvailable('${picked.availableQty}')),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      (from: _fromBranchId, to: _toBranchId, partId: _partId!, qty: qty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.newTransfer),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: spacedFormFields([
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
                controller: _qty,
                decoration: InputDecoration(labelText: l10n.quantity),
                keyboardType: TextInputType.number,
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
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
