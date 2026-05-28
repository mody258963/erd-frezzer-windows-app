import 'package:flutter/material.dart';

import '../../../core/l10n/api_labels.dart';
import '../../../core/theme/app_colors.dart';

/// Receivables or payables summary with top balances.
class FinancePanel extends StatelessWidget {
  const FinancePanel({
    required this.title,
    required this.totalLabel,
    required this.topLabel,
    required this.total,
    required this.items,
    required this.emptyMessage,
    required this.accentColor,
    super.key,
  });

  final String title;
  final String totalLabel;
  final String topLabel;
  final num total;
  final List<Map<String, dynamic>> items;
  final String emptyMessage;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final top = items.take(5).toList();
    final maxBalance = top.isEmpty
        ? 1.0
        : top
            .map(
              (e) => (e['outstanding_balance'] ?? e['balance'] ?? e['debt'] ?? 0)
                  as num,
            )
            .fold<num>(0, (a, b) => a > b ? a : b)
            .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatMoney(context, total),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
            ),
            Text(
              totalLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              topLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (top.isEmpty)
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              for (final item in top) ...[
                const SizedBox(height: 8),
                _BalanceRow(
                  name: item['name'] as String? ??
                      item['customer_name'] as String? ??
                      '—',
                  amount: (item['outstanding_balance'] ??
                      item['balance'] ??
                      item['debt'] ??
                      0) as num,
                  maxAmount: maxBalance,
                  color: accentColor,
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.name,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  final String name;
  final num amount;
  final double maxAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatMoney(context, amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.outline.withValues(alpha: 0.3),
            color: color,
          ),
        ),
      ],
    );
  }
}
