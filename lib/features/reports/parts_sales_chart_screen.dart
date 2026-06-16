import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/branch/branch_filter_scope.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/part_sales_chart_model.dart';
import '../../data/repositories/report_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/parts_sales_line_chart.dart';

class PartsSalesChartScreen extends StatefulWidget {
  const PartsSalesChartScreen({super.key});

  @override
  State<PartsSalesChartScreen> createState() => _PartsSalesChartScreenState();
}

class _PartsSalesChartScreenState extends State<PartsSalesChartScreen> {
  PartSalesChartData? _data;
  String? _error;
  bool _loading = false;

  int _year = DateTime.now().year;
  int _limit = 10;
  String _rankBy = 'units';

  @override
  void initState() {
    super.initState();
    getIt<AppRefreshBus>().addListener(_onAppRefresh);
    _load();
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onAppRefresh);
    super.dispose();
  }

  void _onAppRefresh(AppRefreshKind kind) {
    if (!mounted || kind != AppRefreshKind.branchFilter) return;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await getIt<ReportRepository>().partsSalesChart(
        year: _year,
        limit: _limit,
        rankBy: _rankBy,
        branchId: apiBranchIdFromContext(context),
      );
      setState(() {
        _data = PartSalesChartData.fromJson(raw);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.partsSalesChartTitle,
          subtitle: l10n.partsSalesChartSubtitle,
          actions: [
            IconButton(
              onPressed: () => context.go(RoutePaths.reports),
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<int>(
                  value: _year,
                  decoration: InputDecoration(labelText: l10n.year),
                  items: [
                    for (var y = DateTime.now().year; y >= DateTime.now().year - 5; y--)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _year = v);
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  value: _rankBy,
                  decoration: InputDecoration(labelText: l10n.rankBy),
                  items: [
                    DropdownMenuItem(
                      value: 'units',
                      child: Text(l10n.rankByUnits),
                    ),
                    DropdownMenuItem(
                      value: 'revenue',
                      child: Text(l10n.rankByRevenue),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _rankBy = v);
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  value: _limit,
                  decoration: InputDecoration(labelText: l10n.limit),
                  items: const [5, 10, 15, 20]
                      .map(
                        (n) => DropdownMenuItem(value: n, child: Text('$n')),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _limit = v);
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.show_chart, size: 18),
                label: Text(l10n.runReport),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _data == null
                      ? Center(child: Text(l10n.noData))
                      : _FullChartBody(data: _data!),
        ),
      ],
    );
  }
}

class _FullChartBody extends StatelessWidget {
  const _FullChartBody({required this.data});

  final PartSalesChartData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.salesByMonth,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  PartsSalesLineChart(data: data, height: 280),
                  const SizedBox(height: 12),
                  PartsSalesChartLegend(
                    data: data,
                    onPartTap: (id) {
                      if (id.isNotEmpty) {
                        context.push(RoutePaths.partAnalysis(id));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.topPartsYear(data.year),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (var s = 0; s < data.series.length; s++) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPartSalesChartColors[s %
                          kPartSalesChartColors.length]
                      .withValues(alpha: 0.2),
                  child: Icon(
                    Icons.show_chart,
                    color: kPartSalesChartColors[
                        s % kPartSalesChartColors.length],
                    size: 20,
                  ),
                ),
                title: Text(data.series[s].label),
                subtitle: Text(
                  '${l10n.unitsSold}: ${data.series[s].totalUnitsSold} · '
                  '${l10n.revenue}: ${formatMoney(context, data.series[s].totalRevenue)}',
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  final id = data.series[s].partId;
                  if (id.isNotEmpty) {
                    context.push(RoutePaths.partAnalysis(id));
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
