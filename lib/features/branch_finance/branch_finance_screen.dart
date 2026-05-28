import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/branch_finance_repository.dart';
import '../../di/injection.dart';
import '../shared/branch_dropdown.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/status_chip.dart';

class BranchFinanceScreen extends StatefulWidget {
  const BranchFinanceScreen({super.key});

  @override
  State<BranchFinanceScreen> createState() => _BranchFinanceScreenState();
}

class _BranchFinanceScreenState extends State<BranchFinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<Map<String, dynamic>> _balances = [];
  List<Map<String, dynamic>> _entries = [];
  List<BranchModel> _branches = [];
  String? _error;
  bool _loading = true;

  String? _filterStatus;
  String? _filterEntryType;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _canWrite {
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    return RolePermissions.canPerform(AppAction.branchFinanceWrite, role);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _branches = await loadActiveBranches();
      final repo = getIt<BranchFinanceRepository>();
      final balances = await repo.balances();
      final entries = await repo.entries(
        status: _filterStatus,
        entryType: _filterEntryType,
        perPage: 50,
      );
      setState(() {
        _balances = balances;
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _branchLabel(Map<String, dynamic> row, String idKey, String nestedKey) {
    final nested = row[nestedKey];
    if (nested is Map && nested['name'] != null) return '${nested['name']}';
    final id = row[idKey]?.toString() ?? '';
    return resolveBranchName(branchNameById(_branches), id);
  }

  Future<void> _recordCharge() async {
    if (!_canWrite) return;
    final result = await _showBranchAmountDialog(isPayment: false);
    if (result == null) return;
    try {
      await getIt<BranchFinanceRepository>().createCharge({
        'creditor_branch_id': result.creditorId,
        'debtor_branch_id': result.debtorId,
        'amount': result.amount,
        if (result.description != null && result.description!.isNotEmpty)
          'description': result.description,
        if (result.notes != null && result.notes!.isNotEmpty)
          'notes': result.notes,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.branchChargeSaved)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _recordPayment() async {
    if (!_canWrite) return;
    final result = await _showBranchAmountDialog(isPayment: true);
    if (result == null) return;
    try {
      await getIt<BranchFinanceRepository>().createPayment({
        'creditor_branch_id': result.creditorId,
        'debtor_branch_id': result.debtorId,
        'amount': result.amount,
        if (result.notes != null && result.notes!.isNotEmpty)
          'notes': result.notes,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.branchPaymentSaved)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _settleEntry(String id) async {
    if (!_canWrite) return;
    try {
      await getIt<BranchFinanceRepository>().settle(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.branchEntrySettled)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<_BranchFinanceFormResult?> _showBranchAmountDialog({
    required bool isPayment,
  }) async {
    final l10n = context.l10n;
    if (_branches.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.needTwoBranches)),
      );
      return null;
    }

    String? creditorId = _branches.first.id;
    String? debtorId = _branches[1].id;
    final amount = TextEditingController();
    final description = TextEditingController();
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isPayment ? l10n.recordBranchPayment : l10n.recordBranchCharge,
        ),
        titlePadding: kDialogTitlePadding,
        contentPadding: kDialogContentPadding,
        actionsPadding: kDialogActionsPadding,
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spacedFormFields([
                BranchDropdown(
                  branches: _branches,
                  value: creditorId,
                  label: l10n.creditorBranch,
                  onChanged: (v) => creditorId = v,
                ),
                BranchDropdown(
                  branches: _branches,
                  value: debtorId,
                  label: l10n.debtorBranch,
                  onChanged: (v) => debtorId = v,
                ),
                TextField(
                  controller: amount,
                  decoration: InputDecoration(labelText: l10n.amount),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (!isPayment)
                  TextField(
                    controller: description,
                    decoration: InputDecoration(
                      labelText: l10n.description,
                    ),
                  ),
                TextField(
                  controller: notes,
                  decoration: InputDecoration(labelText: l10n.notesOptional),
                  maxLines: 2,
                ),
              ]),
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
      ),
    );

    if (ok != true ||
        creditorId == null ||
        debtorId == null ||
        creditorId == debtorId) {
      return null;
    }

    final parsed = double.tryParse(amount.text.trim());
    if (parsed == null || parsed <= 0) return null;

    return _BranchFinanceFormResult(
      creditorId: creditorId!,
      debtorId: debtorId!,
      amount: parsed,
      description: description.text.trim(),
      notes: notes.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.branchFinanceTitle,
          subtitle: l10n.branchFinanceSubtitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (_canWrite) ...[
              FilledButton.tonalIcon(
                onPressed: _recordPayment,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(l10n.recordBranchPayment),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _recordCharge,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.recordBranchCharge),
              ),
            ],
          ],
        ),
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.branchBalancesTab),
            Tab(text: l10n.branchLedgerTab),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _BalancesTab(
                          balances: _balances,
                          formatOwed: (v) => formatMoney(context, v),
                        ),
                        _LedgerTab(
                          entries: _entries,
                          canWrite: _canWrite,
                          branchLabel: _branchLabel,
                          onSettle: _settleEntry,
                          filterStatus: _filterStatus,
                          filterEntryType: _filterEntryType,
                          onFilterChanged: (status, type) {
                            setState(() {
                              _filterStatus = status;
                              _filterEntryType = type;
                            });
                            _load();
                          },
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _BranchFinanceFormResult {
  const _BranchFinanceFormResult({
    required this.creditorId,
    required this.debtorId,
    required this.amount,
    this.description,
    this.notes,
  });

  final String creditorId;
  final String debtorId;
  final double amount;
  final String? description;
  final String? notes;
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab({
    required this.balances,
    required this.formatOwed,
  });

  final List<Map<String, dynamic>> balances;
  final String Function(num?) formatOwed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (balances.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final b in balances)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.branchBalanceRow(
                        '${b['debtor_branch_name'] ?? '—'}',
                        '${b['creditor_branch_name'] ?? '—'}',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _BalanceChip(
                          label: l10n.balanceOwed,
                          value: formatOwed(b['balance_owed']),
                          highlight: true,
                        ),
                        _BalanceChip(
                          label: l10n.totalCharges,
                          value: formatOwed(b['total_charges']),
                        ),
                        _BalanceChip(
                          label: l10n.totalPayments,
                          value: formatOwed(b['total_payments']),
                        ),
                        _BalanceChip(
                          label: l10n.openChargesCount,
                          value: '${b['open_charges_count'] ?? 0}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryContainer.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTab extends StatelessWidget {
  const _LedgerTab({
    required this.entries,
    required this.canWrite,
    required this.branchLabel,
    required this.onSettle,
    required this.filterStatus,
    required this.filterEntryType,
    required this.onFilterChanged,
  });

  final List<Map<String, dynamic>> entries;
  final bool canWrite;
  final String Function(Map<String, dynamic>, String, String) branchLabel;
  final Future<void> Function(String id) onSettle;
  final String? filterStatus;
  final String? filterEntryType;
  final void Function(String? status, String? entryType) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.filterAll),
                selected: filterStatus == null && filterEntryType == null,
                onSelected: (_) => onFilterChanged(null, null),
              ),
              FilterChip(
                label: Text(l10n.statusOpen),
                selected: filterStatus == 'open',
                onSelected: (_) => onFilterChanged('open', filterEntryType),
              ),
              FilterChip(
                label: Text(l10n.entryTypeCharge),
                selected: filterEntryType == 'charge',
                onSelected: (_) => onFilterChanged(filterStatus, 'charge'),
              ),
              FilterChip(
                label: Text(l10n.entryTypePayment),
                selected: filterEntryType == 'payment',
                onSelected: (_) => onFilterChanged(filterStatus, 'payment'),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(child: Text(l10n.noData))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final id = '${e['id']}';
                    final entryType = '${e['entry_type'] ?? ''}';
                    final status = '${e['status'] ?? ''}';
                    final creditor = branchLabel(
                      e,
                      'creditor_branch_id',
                      'creditor_branch',
                    );
                    final debtor = branchLabel(
                      e,
                      'debtor_branch_id',
                      'debtor_branch',
                    );
                    final canSettle = canWrite &&
                        entryType == 'charge' &&
                        status == 'open';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${e['entry_number'] ?? id}'),
                        subtitle: Text(
                          l10n.branchLedgerRow(
                            debtor,
                            creditor,
                            formatMoney(
                              context,
                              e['amount'] is num ? e['amount'] as num : null,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusChip(
                              label: localizeBranchEntryType(context, entryType),
                              variant: entryType == 'payment'
                                  ? StatusChipVariant.success
                                  : StatusChipVariant.warning,
                            ),
                            const SizedBox(width: 6),
                            if (canSettle)
                              IconButton(
                                tooltip: l10n.markSettled,
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => onSettle(id),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
