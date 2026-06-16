import 'package:flutter/material.dart';

import '../../../core/auth/role_permissions.dart';
import '../../../core/branch/branch_filter_scope.dart';
import '../../../core/events/app_refresh_bus.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/capital_model.dart';
import '../../../data/models/user_role.dart';
import '../../../data/repositories/capital_repository.dart';
import '../../../di/injection.dart';
import '../../shared/financing_snapshot_panel.dart';
import '../../shared/form_field_spacing.dart';
import '../../shared/loading_error.dart';

/// Owner capital + financing snapshot (`/settings/capital`).
class BusinessCapitalCard extends StatefulWidget {
  const BusinessCapitalCard({
    required this.role,
    super.key,
  });

  final UserRole role;

  @override
  State<BusinessCapitalCard> createState() => _BusinessCapitalCardState();
}

class _BusinessCapitalCardState extends State<BusinessCapitalCard> {
  CapitalSettings? _settings;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  bool get _canView =>
      RolePermissions.canPerform(AppAction.capitalView, widget.role);
  bool get _canEdit =>
      RolePermissions.canPerform(AppAction.capitalEdit, widget.role);

  @override
  void initState() {
    super.initState();
    if (_canView) {
      getIt<AppRefreshBus>().addListener(_onRefresh);
      _load();
    }
  }

  @override
  void dispose() {
    if (_canView) {
      getIt<AppRefreshBus>().removeListener(_onRefresh);
    }
    super.dispose();
  }

  void _onRefresh(AppRefreshKind kind) {
    if (!mounted || kind != AppRefreshKind.branchFilter) return;
    _load();
  }

  String? get _branchId => apiBranchIdFromContext(context);

  Future<void> _load() async {
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

  Future<void> _save() async {
    final l10n = context.l10n;
    final amountCtrl = TextEditingController(
      text: _settings?.capitalAmount.toStringAsFixed(0) ?? '',
    );
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.businessCapitalUpdateTitle),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: spacedFormFields([
                TextField(
                  controller: amountCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.businessCapitalAmount,
                    suffixText: _settings?.currency ?? 'EGP',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(labelText: l10n.reason),
                ),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(labelText: l10n.notes),
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

    if (ok != true || !mounted) {
      amountCtrl.dispose();
      reasonCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    final amount = double.tryParse(amountCtrl.text.trim());
    final reason = reasonCtrl.text.trim();
    final notes = notesCtrl.text.trim();
    amountCtrl.dispose();
    reasonCtrl.dispose();
    notesCtrl.dispose();

    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidAmount)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await getIt<CapitalRepository>().update(
        capitalAmount: amount,
        reason: reason.isEmpty ? l10n.businessCapitalDefaultReason : reason,
        notes: notes.isNotEmpty ? notes : null,
        branchId: _branchId,
      );
      if (!mounted) return;
      setState(() {
        _settings = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.businessCapitalSaved)),
      );
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _showHistory() async {
    final l10n = context.l10n;
    try {
      final rows = await getIt<CapitalRepository>().adjustments(
        branchId: _branchId,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.businessCapitalHistory),
          content: SizedBox(
            width: 480,
            height: 320,
            child: rows.isEmpty
                ? Center(child: Text(l10n.noData))
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      final at = r['created_at'] as String? ?? '';
                      final type = r['type'] as String? ?? '';
                      final change = r['change_amount'] ?? r['amount'];
                      final isCashOut = type == 'owner_cash_out';
                      return ListTile(
                        title: Text(
                          [
                            if (isCashOut) l10n.ownerCashOutTitle,
                            r['reason'] ?? '—',
                            if (change != null) change,
                          ].where((e) => '$e'.isNotEmpty).join(' · '),
                        ),
                        subtitle: Text(
                          '${at.length >= 10 ? at.substring(0, 10) : at}${r['notes'] != null ? '\n${r['notes']}' : ''}',
                        ),
                        dense: true,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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

  @override
  Widget build(BuildContext context) {
    if (!_canView) return const SizedBox.shrink();

    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.savings_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.businessCapitalTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_canEdit && !_loading)
                  IconButton(
                    tooltip: l10n.businessCapitalHistory,
                    onPressed: _showHistory,
                    icon: const Icon(Icons.history),
                  ),
                if (_canEdit && !_loading)
                  FilledButton.tonal(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.businessCapitalSet),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _canEdit
                  ? l10n.businessCapitalSubtitleAdmin
                  : l10n.businessCapitalSubtitleView,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ErrorView(message: _error!, onRetry: _load)
            else if (_settings != null) ...[
              if (_settings!.financingSnapshot != null)
                FinancingSnapshotPanel(
                  snapshot: _settings!.financingSnapshot!,
                  capitalAmount: _settings!.capitalAmount,
                  currency: _settings!.currency,
                )
              else
                Text(
                  l10n.businessCapitalNotSet,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
