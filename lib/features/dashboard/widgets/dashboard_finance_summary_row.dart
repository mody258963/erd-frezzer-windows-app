import 'package:flutter/material.dart';

import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../dashboard_summary_utils.dart';

/// Headline money fields from `GET /dashboard/summary` (receivables, payables, stock).
class DashboardFinanceSummaryRow extends StatelessWidget {
  const DashboardFinanceSummaryRow({required this.summary, super.key});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final receivables = summaryNum(summary, 'total_receivables');
    final supplierDebt = summaryNum(summary, 'total_supplier_debt');
    final stockCost = summaryNum(summary, 'total_stock_value_cost');

    final hasAny = receivables > 0 || supplierDebt > 0 || stockCost > 0;
    if (!hasAny &&
        !summary.containsKey('total_receivables') &&
        !summary.containsKey('total_supplier_debt') &&
        !summary.containsKey('total_stock_value_cost')) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FinanceCard(
          label: l10n.totalReceivable,
          value: formatMoney(context, receivables),
          icon: Icons.account_balance_wallet_outlined,
          color: Theme.of(context).colorScheme.primary,
          highlight: receivables > 0,
        ),
        _FinanceCard(
          label: l10n.totalSupplierDebt,
          value: formatMoney(context, supplierDebt),
          icon: Icons.local_shipping_outlined,
          color: AppColors.secondary,
          highlight: supplierDebt > 0,
        ),
        _FinanceCard(
          label: l10n.capitalInventoryAtCost,
          value: formatMoney(context, stockCost),
          icon: Icons.inventory_2_outlined,
          color: AppColors.tertiary,
        ),
      ],
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: highlight ? color.withValues(alpha: 0.5) : AppColors.outline,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
