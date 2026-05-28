import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/part_sales_chart_model.dart';

/// Distinct colors for multi-series part sales charts.
const List<Color> kPartSalesChartColors = [
  Color(0xFF5C6BC0),
  Color(0xFF26A69A),
  Color(0xFFEF5350),
  Color(0xFFFFA726),
  Color(0xFFAB47BC),
  Color(0xFF42A5F5),
  Color(0xFF8D6E63),
  Color(0xFF66BB6A),
  Color(0xFFEC407A),
  Color(0xFF78909C),
];

/// Monthly multi-line chart: one line per top-selling part.
class PartsSalesLineChart extends StatelessWidget {
  const PartsSalesLineChart({
    required this.data,
    super.key,
    this.height = 240,
    this.colors = kPartSalesChartColors,
    this.showDots,
  });

  final PartSalesChartData data;
  final double height;
  final List<Color> colors;
  final bool? showDots;

  @override
  Widget build(BuildContext context) {
    final months = data.months;
    final byRevenue = data.rankByRevenue;
    final dots = showDots ?? data.series.length <= 5;

    if (data.series.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            context.l10n.noData,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.outline.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= months.length) {
                    return const SizedBox.shrink();
                  }
                  final label = months[i];
                  final short =
                      label.length >= 7 ? label.substring(5) : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      short,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            for (var s = 0; s < data.series.length; s++)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < months.length; i++)
                    FlSpot(
                      i.toDouble(),
                      data.series[s].valueAtMonthIndex(
                        months,
                        i,
                        byRevenue,
                      ),
                    ),
                ],
                isCurved: true,
                color: colors[s % colors.length],
                barWidth: 2.5,
                dotData: FlDotData(show: dots),
              ),
          ],
        ),
      ),
    );
  }
}

/// Color-coded legend for [PartsSalesLineChart] series.
class PartsSalesChartLegend extends StatelessWidget {
  const PartsSalesChartLegend({
    required this.data,
    super.key,
    this.colors = kPartSalesChartColors,
    this.onPartTap,
    this.compact = false,
  });

  final PartSalesChartData data;
  final List<Color> colors;
  final void Function(String partId)? onPartTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (data.series.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var s = 0; s < data.series.length; s++)
          InkWell(
            onTap: onPartTap != null
                ? () => onPartTap!(data.series[s].partId)
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: colors[s % colors.length].withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors[s % colors.length].withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[s % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      compact
                          ? data.series[s].code.isNotEmpty
                              ? data.series[s].code
                              : data.series[s].name
                          : data.series[s].label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${data.series[s].totalUnitsSold}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
