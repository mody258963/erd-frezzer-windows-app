import 'package:flutter/material.dart';

import '../../../core/dashboard/dashboard_period.dart';
import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../daily_profit.dart';
import '../dashboard_period_labels.dart';

/// Hero block: profit summary with three equal metric tiles across the width.
class DailyProfitPanel extends StatelessWidget {
  const DailyProfitPanel({
    required this.metrics,
    super.key,
  });

  final DailyProfitMetrics metrics;

  static const double _chipGap = 12;
  static const double _minChipHeight = 96;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profit = metrics.profit;
    final profitColor =
        profit >= 0 ? AppColors.success : Theme.of(context).colorScheme.error;
    final margin = metrics.marginPercent;
    final chips = _buildChips(context, l10n);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: profitColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: profitColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: profitColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        dashboardProfitTitle(context, _dashboardPeriod(metrics)),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (metrics.estimated)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.todayProfitEstimated,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MoneyText(
              text: formatMoney(context, profit),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: profitColor,
                    height: 1.15,
                  ),
            ),
            const SizedBox(height: 4),
            _MoneyText(
              text: l10n.profitMargin(margin.toStringAsFixed(1)),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: profitColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400 && chips.length > 1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < chips.length; i++) ...[
                        if (i > 0) const SizedBox(height: _chipGap),
                        chips[i],
                      ],
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < chips.length; i++) ...[
                        if (i > 0) const SizedBox(width: _chipGap),
                        Expanded(child: chips[i]),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChips(BuildContext context, AppLocalizations l10n) {
    if (metrics.isPeriodScoped) {
      return [
        _MetricChip(
          label: l10n.periodNetSales,
          value: formatMoney(context, metrics.sales),
          icon: Icons.trending_up_outlined,
        ),
        if (metrics.periodGrossProfit > 0)
          _MetricChip(
            label: l10n.periodGrossProfit,
            value: formatMoney(context, metrics.periodGrossProfit),
            icon: Icons.show_chart_outlined,
          ),
        if (metrics.costOfGoods > 0)
          _MetricChip(
            label: l10n.costOfGoods,
            value: formatMoney(context, metrics.costOfGoods),
            icon: Icons.shopping_bag_outlined,
          ),
        if (metrics.periodDiscount > 0)
          _MetricChip(
            label: l10n.periodDiscount,
            value: formatMoney(context, metrics.periodDiscount),
            icon: Icons.discount_outlined,
            accent: AppColors.warning,
          ),
        if (metrics.customerRefunds > 0)
          _MetricChip(
            label: l10n.periodCustomerRefunds,
            value: formatMoney(context, metrics.customerRefunds),
            icon: Icons.undo_outlined,
            accent: AppColors.warning,
          ),
        if (metrics.refundProfitImpact > 0)
          _MetricChip(
            label: l10n.refundProfitImpact,
            value: formatMoney(context, metrics.refundProfitImpact),
            icon: Icons.trending_down_outlined,
            accent: AppColors.warning,
          ),
      ];
    }

    final chips = <Widget>[
      _MetricChip(
        label: l10n.todaySales,
        value: formatMoney(context, metrics.sales),
        icon: Icons.point_of_sale_outlined,
      ),
      _MetricChip(
        label: l10n.costOfGoods,
        value: formatMoney(context, metrics.costOfGoods),
        icon: Icons.shopping_bag_outlined,
      ),
    ];
    if (metrics.invoiceCount > 0) {
      chips.add(
        _MetricChip(
          label: l10n.todayInvoices,
          value: '${metrics.invoiceCount}',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }
    return chips;
  }

  DashboardPeriod _dashboardPeriod(DailyProfitMetrics metrics) {
    return switch (metrics.period) {
      ProfitPeriod.daily => DashboardPeriod.day,
      ProfitPeriod.weekly => DashboardPeriod.week,
      ProfitPeriod.monthly => DashboardPeriod.month,
    };
  }
}

/// Keeps currency figures LTR and aligned predictably in Arabic UI.
class _MoneyText extends StatelessWidget {
  const _MoneyText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final iconColor = accent ?? Theme.of(context).colorScheme.primary;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: DailyProfitPanel._minChipHeight,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 8),
            _MoneyText(
              text: value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
