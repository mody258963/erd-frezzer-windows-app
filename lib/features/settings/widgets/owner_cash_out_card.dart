import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/role_permissions.dart';
import '../../../core/branch/branch_filter_scope.dart';
import '../../../core/events/app_refresh_bus.dart';
import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/capital_model.dart';
import '../../../data/models/user_role.dart';
import '../../../data/repositories/capital_repository.dart';
import '../../../di/injection.dart';
import '../../shared/form_field_spacing.dart';
import '../../shared/loading_error.dart';

/// Admin-only owner withdrawal from realized profit (not opening cash).
class OwnerCashOutCard extends StatefulWidget {
  const OwnerCashOutCard({required this.role, super.key});

  final UserRole role;

  @override
  State<OwnerCashOutCard> createState() => _OwnerCashOutCardState();
}

class _OwnerCashOutCardState extends State<OwnerCashOutCard> {
  CapitalSettings? _settings;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

  bool get _canCashOut =>
      RolePermissions.canPerform(AppAction.capitalEdit, widget.role);

  @override
  void initState() {
    super.initState();
    if (_canCashOut) {
      getIt<AppRefreshBus>().addListener(_onRefresh);
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    if (_canCashOut) {
      getIt<AppRefreshBus>().removeListener(_onRefresh);
    }
    super.dispose();
  }

  void _onRefresh(AppRefreshKind kind) {
    if (!mounted) return;
    if (kind == AppRefreshKind.branchFilter ||
        kind == AppRefreshKind.dashboard) {
      _load();
    }
  }

  String? get _branchId => apiBranchIdFromContext(context);

  double get _withdrawable => _settings?.withdrawableProfit ?? 0;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await getIt<CapitalRepository>().get(branchId: _branchId);
      if (!mounted) return;
      setState(() {
        _settings = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showCashOutHistory() async {
    final l10n = context.l10n;
    try {
      final rows = await getIt<CapitalRepository>().cashOuts(
        branchId: _branchId,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.ownerCashOutHistory),
          content: SizedBox(
            width: 480,
            height: 320,
            child: rows.isEmpty
                ? Center(child: Text(l10n.noData))
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final amount = r['amount'];
                      final at = r['created_at'] as String? ?? '';
                      final by = r['created_by'] is Map
                          ? (r['created_by'] as Map)['name']
                          : null;
                      return ListTile(
                        title: Text(
                          formatMoney(
                            context,
                            amount is num ? amount : num.tryParse('$amount'),
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (r['reason'] != null) '${r['reason']}',
                            if (by != null) by,
                            if (at.length >= 10) at.substring(0, 10),
                            if (r['notes'] != null) '${r['notes']}',
                          ].join(' · '),
                        ),
                        dense: true,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _confirmCashOut() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final settings = _settings;
    if (settings == null) return;

    final maxAmount = _withdrawable;
    if (maxAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noWithdrawableProfit)),
      );
      return;
    }

    final currency = settings.currency;
    final withdrawableText = '${formatMoney(context, maxAmount)} $currency';
    final realizedText =
        '${formatMoney(context, settings.realizedProfit)} $currency';
    final withdrawnText =
        '${formatMoney(context, settings.totalProfitWithdrawn)} $currency';
    final openingCashText =
        '${formatMoney(context, settings.openingCashBalance)} $currency';

    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final raw = amountCtrl.text.trim().replaceAll(',', '');
            final amount = double.tryParse(raw);
            final canConfirm = amount != null && amount > 0 && amount <= maxAmount;

            return AlertDialog(
              title: Text(l10n.withdrawFromProfit),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.ownerCashOutDialogHint,
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(dialogContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryLine(
                        label: l10n.withdrawableProfit,
                        value: withdrawableText,
                        highlight: true,
                      ),
                      _SummaryLine(
                        label: l10n.realizedProfit,
                        value: realizedText,
                      ),
                      _SummaryLine(
                        label: l10n.totalProfitWithdrawn,
                        value: withdrawnText,
                      ),
                      _SummaryLine(
                        label: l10n.openingCashBalance,
                        value: openingCashText,
                      ),
                      const SizedBox(height: 16),
                      ...spacedFormFields([
                        TextField(
                          controller: amountCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.ownerCashOutAmount,
                            suffixText: currency,
                            helperText: l10n.ownerCashOutAmountInvalid(
                              maxAmount.toStringAsFixed(2),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        TextField(
                          controller: reasonCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.ownerCashOutReason,
                          ),
                        ),
                        TextField(
                          controller: notesCtrl,
                          decoration:
                              InputDecoration(labelText: l10n.notesOptional),
                          maxLines: 2,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: canConfirm
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: Text(l10n.ownerCashOutConfirm),
                ),
              ],
            );
          },
        );
      },
    );

    final amount = double.tryParse(
      amountCtrl.text.trim().replaceAll(',', ''),
    );
    final reason = reasonCtrl.text.trim();
    final notes = notesCtrl.text.trim();
    amountCtrl.dispose();
    reasonCtrl.dispose();
    notesCtrl.dispose();

    if (ok != true || !mounted) return;

    if (amount == null || amount <= 0 || amount > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.ownerCashOutAmountInvalid(maxAmount.toStringAsFixed(2)),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final updated = await getIt<CapitalRepository>().cashOut(
        amount: amount,
        reason: reason.isNotEmpty ? reason : null,
        notes: notes.isNotEmpty ? notes : null,
        branchId: _branchId,
      );
      if (!mounted) return;
      setState(() {
        _settings = updated;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profitWithdrawnSuccess),
          backgroundColor: Colors.green.shade700,
        ),
      );
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? e.message ?? e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canCashOut) return const SizedBox.shrink();

    final l10n = context.l10n;
    final settings = _settings;
    final canWithdraw = !_loading && _withdrawable > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.output_outlined, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.withdrawFromProfit,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (!_loading)
                  IconButton(
                    tooltip: l10n.ownerCashOutHistory,
                    onPressed: _showCashOutHistory,
                    icon: const Icon(Icons.history),
                  ),
                if (!_loading)
                  FilledButton.tonal(
                    onPressed: _submitting || !canWithdraw
                        ? null
                        : _confirmCashOut,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.ownerCashOutRecord),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ownerCashOutSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorView(message: _error!, onRetry: _load),
            ] else if (settings != null) ...[
              const SizedBox(height: 16),
              _SummaryLine(
                label: l10n.withdrawableProfit,
                value:
                    '${formatMoney(context, _withdrawable)} ${settings.currency}',
                highlight: true,
              ),
              _SummaryLine(
                label: l10n.realizedProfit,
                value:
                    '${formatMoney(context, settings.realizedProfit)} ${settings.currency}',
              ),
              _SummaryLine(
                label: l10n.totalProfitWithdrawn,
                value:
                    '${formatMoney(context, settings.totalProfitWithdrawn)} ${settings.currency}',
              ),
              if (_withdrawable <= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.noWithdrawableProfit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
