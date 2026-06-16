import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/capital_model.dart';

/// Stock + receivables vs owner capital (from API `financing_snapshot`).
class FinancingSnapshotPanel extends StatelessWidget {
  const FinancingSnapshotPanel({
    required this.snapshot,
    this.capitalAmount,
    this.currency,
    this.compact = false,
    super.key,
  });

  final FinancingSnapshot snapshot;
  final double? capitalAmount;
  final String? currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    String money(num? v) {
      final formatted = formatMoney(context, v);
      if (currency == null || currency!.isEmpty) return formatted;
      return '$formatted $currency';
    }

    final tiles = <_FinTile>[
      if (capitalAmount != null && capitalAmount! > 0)
        _FinTile(
          l10n.businessCapitalAmount,
          money(capitalAmount),
          Icons.account_balance_wallet_outlined,
          AppColors.primary,
        ),
      _FinTile(
        l10n.capitalInventoryAtCost,
        money(snapshot.inventoryAtCost),
        Icons.inventory_2_outlined,
        AppColors.secondary,
      ),
      _FinTile(
        l10n.capitalCustomerReceivables,
        money(snapshot.customerReceivables),
        Icons.people_outline,
        AppColors.tertiary,
      ),
      _FinTile(
        l10n.capitalSupplierDebt,
        money(snapshot.supplierDebt),
        Icons.local_shipping_outlined,
        AppColors.warning,
      ),
      _FinTile(
        l10n.capitalDeployed,
        money(snapshot.deployedCapital),
        Icons.pie_chart_outline,
        AppColors.primary,
      ),
      _FinTile(
        l10n.capitalEstimatedAvailable,
        money(snapshot.estimatedAvailable),
        Icons.savings_outlined,
        snapshot.estimatedAvailable >= 0
            ? AppColors.success
            : Theme.of(context).colorScheme.error,
      ),
    ];

    if (compact) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final t in tiles)
            _CompactChip(label: t.label, value: t.value, color: t.color),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 720 ? 3 : (w > 400 ? 2 : 1);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final t in tiles) _FinCard(tile: t),
          ],
        );
      },
    );
  }
}

class _FinTile {
  const _FinTile(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _FinCard extends StatelessWidget {
  const _FinCard({required this.tile});

  final _FinTile tile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tile.icon, size: 20, color: tile.color),
          const Spacer(),
          Text(
            tile.value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            tile.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
