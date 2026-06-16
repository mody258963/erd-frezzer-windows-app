import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/capital_model.dart';
import '../../../router/route_paths.dart';
import '../../shared/financing_snapshot_panel.dart';

/// Capital headline from `GET /dashboard/summary`.
class BusinessCapitalBanner extends StatelessWidget {
  const BusinessCapitalBanner({
    required this.summary,
    super.key,
  });

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final capital = summary['business_capital'];
    if (capital == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final currency = '${summary['capital_currency'] ?? 'EGP'}';
    final available = summary['capital_estimated_available'];
    final snapRaw = summary['financing_snapshot'] ?? summary['capital'];
    final snapshot = snapRaw is Map<String, dynamic>
        ? FinancingSnapshot.fromJson(snapRaw)
        : null;

    String money(num? v) {
      final f = formatMoney(context, v);
      return currency.isEmpty ? f : '$f $currency';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.savings_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.businessCapitalTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(RoutePaths.settings),
                  child: Text(l10n.settingsTitle),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _HeadlineChip(
                  label: l10n.businessCapitalAmount,
                  value: money(capital is num ? capital : num.tryParse('$capital')),
                ),
                if (available != null)
                  _HeadlineChip(
                    label: l10n.capitalEstimatedAvailable,
                    value: money(
                      available is num ? available : num.tryParse('$available'),
                    ),
                    highlight: true,
                  ),
              ],
            ),
            if (snapshot != null &&
                (snapshot.deployedCapital > 0 ||
                    snapshot.inventoryAtCost > 0)) ...[
              const SizedBox(height: 14),
              FinancingSnapshotPanel(
                snapshot: snapshot,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeadlineChip extends StatelessWidget {
  const _HeadlineChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.success : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
