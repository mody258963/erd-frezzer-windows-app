import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

/// `business_capital` = inventory at cost + realized cash on hand.
class BusinessCapitalBreakdown extends StatelessWidget {
  const BusinessCapitalBreakdown({
    required this.businessCapital,
    required this.inventoryAtCost,
    required this.cashOnHandRealized,
    this.openingCashBalance,
    this.currency,
    this.compact = false,
    this.showOpeningCash = false,
    super.key,
  });

  final double businessCapital;
  final double inventoryAtCost;
  final double cashOnHandRealized;
  final double? openingCashBalance;
  final String? currency;
  final bool compact;
  final bool showOpeningCash;

  String _money(BuildContext context, num? v) {
    final formatted = formatMoney(context, v);
    if (currency == null || currency!.isEmpty) return formatted;
    return '$formatted $currency';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final components = <_CapitalRow>[
      _CapitalRow(
        l10n.capitalInventoryAtCost,
        _money(context, inventoryAtCost),
        Icons.inventory_2_outlined,
        AppColors.secondary,
      ),
      _CapitalRow(
        l10n.cashOnHandRealized,
        _money(context, cashOnHandRealized),
        Icons.payments_outlined,
        AppColors.success,
      ),
      if (showOpeningCash && openingCashBalance != null)
        _CapitalRow(
          l10n.openingCashBalance,
          _money(context, openingCashBalance),
          Icons.account_balance_wallet_outlined,
          AppColors.primary,
        ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _money(context, businessCapital),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
          ),
          Text(
            l10n.businessCapitalTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final row in components)
                _CompactChip(
                  label: row.label,
                  value: row.value,
                  color: row.color,
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _money(context, businessCapital),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
        Text(
          l10n.businessCapitalTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.businessCapitalFormulaHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < components.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ComponentRow(row: components[i]),
        ],
      ],
    );
  }
}

class _CapitalRow {
  const _CapitalRow(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({required this.row});

  final _CapitalRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(row.icon, size: 20, color: row.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            row.label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          row.value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
