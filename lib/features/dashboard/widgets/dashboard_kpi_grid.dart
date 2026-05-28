import 'package:flutter/material.dart';

import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../daily_profit.dart';
import 'daily_profit_panel.dart';

class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({
    required this.summary,
    this.dailyProfit,
    super.key,
  });

  final Map<String, dynamic> summary;
  final DailyProfitMetrics? dailyProfit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final lowStock = (summary['low_stock_count'] as num?)?.toInt() ?? 0;
    final overdue = (summary['overdue_installments'] as num?)?.toInt() ?? 0;
    final pendingCredit = (summary['pending_credit_invoices'] as num?)?.toInt() ?? 0;
    final attention = lowStock + overdue + pendingCredit;

    final kpiTiles = <Widget>[
      if (dailyProfit == null)
        _KpiTile(
          label: l10n.todaySales,
          value: formatMoney(context, summary['today_sales'] as num?),
          icon: Icons.point_of_sale_rounded,
          color: scheme.primary,
        ),
      _KpiTile(
        label: l10n.lowStock,
        value: '$lowStock',
        icon: Icons.inventory_2_outlined,
        color: AppColors.warning,
        highlight: lowStock > 0,
      ),
      _KpiTile(
        label: l10n.overdueInstallments,
        value: '$overdue',
        icon: Icons.schedule_rounded,
        color: AppColors.secondary,
        highlight: overdue > 0,
      ),
      _KpiTile(
        label: l10n.pendingCredit,
        value: '$pendingCredit',
        icon: Icons.credit_card_outlined,
        color: AppColors.tertiary,
        highlight: pendingCredit > 0,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attention > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AlertBanner(
              label: l10n.dashboardNeedsAttention,
              count: attention,
              color: AppColors.warning,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AlertBanner(
              label: l10n.dashboardAllClear,
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
        if (dailyProfit != null) ...[
          DailyProfitPanel(metrics: dailyProfit!),
          const SizedBox(height: 16),
        ],
        _KpiTileRow(tiles: kpiTiles),
      ],
    );
  }
}

/// Full-width row of KPI cards with equal width per tile.
class _KpiTileRow extends StatelessWidget {
  const _KpiTileRow({required this.tiles});

  final List<Widget> tiles;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520 && tiles.length > 2) {
          final half = (tiles.length / 2).ceil();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _rowChildren(tiles.sublist(0, half)),
                ),
              ),
              const SizedBox(height: _gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _rowChildren(tiles.sublist(half)),
                ),
              ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _rowChildren(tiles),
          ),
        );
      },
    );
  }

  List<Widget> _rowChildren(List<Widget> rowTiles) {
    return [
      for (var i = 0; i < rowTiles.length; i++) ...[
        if (i > 0) const SizedBox(width: _gap),
        Expanded(child: rowTiles[i]),
      ],
    ];
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.label,
    required this.color,
    this.count,
    this.icon,
  });

  final String label;
  final int? count;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count != null ? '$label ($count)' : label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlight ? color.withValues(alpha: 0.5) : AppColors.outline,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                if (highlight) Icon(Icons.circle, size: 8, color: color),
              ],
            ),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
