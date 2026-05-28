import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../data/models/part_sales_chart_model.dart';
import '../../../router/route_paths.dart';
import '../../shared/parts_sales_line_chart.dart';

/// Dashboard card: top parts sold by month (yearly trend).
class PartsSalesChartPanel extends StatelessWidget {
  const PartsSalesChartPanel({
    required this.data,
    super.key,
  });

  final PartSalesChartData? data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.partsSalesChartTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data != null
                            ? l10n.dashboardPartsChartSubtitle(data!.year)
                            : l10n.partsSalesChartSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.go(RoutePaths.reportsPartsSalesChart),
                  child: Text(l10n.viewFullChart),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (data == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  l10n.noProductData,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else ...[
              PartsSalesLineChart(data: data!, height: 260),
              const SizedBox(height: 14),
              PartsSalesChartLegend(
                data: data!,
                compact: data!.series.length > 4,
                onPartTap: (id) {
                  if (id.isNotEmpty) {
                    context.push(RoutePaths.partAnalysis(id));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
