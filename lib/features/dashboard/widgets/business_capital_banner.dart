import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/capital_model.dart';
import '../../../router/route_paths.dart';
import '../../shared/business_capital_breakdown.dart';

/// Capital headline from `GET /dashboard/summary`.
class BusinessCapitalBanner extends StatelessWidget {
  const BusinessCapitalBanner({
    required this.summary,
    super.key,
  });

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final businessCapital = summary['business_capital'];
    if (businessCapital == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final currency = '${summary['capital_currency'] ?? 'EGP'}';
    final stock = _num(summary['total_stock_value_cost']);
    final cash = _num(summary['cash_on_hand_realized']);
    final total = businessCapital is num
        ? businessCapital.toDouble()
        : double.tryParse('$businessCapital') ?? stock + cash;

    final snapRaw = summary['financing_snapshot'];
    if (stock <= 0 && snapRaw is Map<String, dynamic>) {
      final snap = FinancingSnapshot.fromJson(snapRaw);
      if (snap.inventoryAtCost > 0) {
        return _card(
          context,
          l10n,
          currency,
          total: total > 0 ? total : snap.businessCapital,
          stock: snap.inventoryAtCost,
          cash: cash > 0 ? cash : snap.cashOnHandRealized,
        );
      }
    }

    return _card(
      context,
      l10n,
      currency,
      total: total,
      stock: stock,
      cash: cash,
    );
  }

  Widget _card(
    BuildContext context,
    dynamic l10n,
    String currency, {
    required double total,
    required double stock,
    required double cash,
  }) {
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
            BusinessCapitalBreakdown(
              businessCapital: total,
              inventoryAtCost: stock,
              cashOnHandRealized: cash,
              currency: currency,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
