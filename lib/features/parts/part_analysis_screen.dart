import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/part_analysis_model.dart';
import '../../data/repositories/part_repository.dart';
import '../../di/injection.dart';
import '../shared/branch_dropdown.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class PartAnalysisScreen extends StatefulWidget {
  const PartAnalysisScreen({required this.partId, super.key});

  final String partId;

  @override
  State<PartAnalysisScreen> createState() => _PartAnalysisScreenState();
}

class _PartAnalysisScreenState extends State<PartAnalysisScreen> {
  PartAnalysisData? _data;
  String? _error;
  bool _loading = false;
  bool _loaded = false;

  late DateTimeRange _range;
  String? _branchId;
  List<BranchModel> _branches = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _branchId = context.read<AuthCubit>().state.user?.branchId;
    _loadBranches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<ConnectivityCubit>().state.isOnline) {
        _load();
      }
    });
  }

  bool get _canPickBranch =>
      context.read<AuthCubit>().state.user?.branchId == null;

  Future<void> _loadBranches() async {
    if (!_canPickBranch) return;
    try {
      _branches = await loadActiveBranches();
    } catch (_) {}
  }

  String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _load() async {
    if (!context.read<ConnectivityCubit>().state.isOnline) {
      setState(() {
        _error = context.l10n.partAnalysisOnlineOnly;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await getIt<PartRepository>().analysis(
        widget.partId,
        from: _isoDate(_range.start),
        to: _isoDate(_range.end),
        branchId: _branchId,
      );
      setState(() {
        _data = PartAnalysisData.fromJson(raw);
        _loading = false;
        _loaded = true;
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
    final online = context.watch<ConnectivityCubit>().state.isOnline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: _data?.partTitle ?? l10n.partAnalysisTitle,
          subtitle: _loaded && _data != null
              ? l10n.reportDateRange(
                  _data!.period.from ?? '—',
                  _data!.period.to ?? '—',
                )
              : l10n.partAnalysisSubtitle,
          actions: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            if (online)
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
              OutlinedButton.icon(
                onPressed: online ? _pickRange : null,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  l10n.reportDateRange(
                    _isoDate(_range.start),
                    _isoDate(_range.end),
                  ),
                ),
              ),
              if (_canPickBranch && _branches.isNotEmpty)
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    value: _branchId != null &&
                            _branches.any((b) => b.id == _branchId)
                        ? _branchId
                        : null,
                    decoration: InputDecoration(labelText: l10n.selectBranch),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        child: Text(l10n.allBranches),
                      ),
                      for (final b in _branches)
                        DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                ),
              FilledButton.icon(
                onPressed: online && !_loading ? _load : null,
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: Text(l10n.runReport),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!online)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MaterialBanner(
              content: Text(l10n.partAnalysisOnlineOnly),
              leading: const Icon(Icons.cloud_off),
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                  child: Text(l10n.dismiss),
                ),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : !_loaded || _data == null
                      ? Center(
                          child: Text(
                            l10n.reportTapRun,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        )
                      : _AnalysisBody(data: _data!),
        ),
      ],
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.data});

  final PartAnalysisData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricSection(
            title: context.l10n.stockLevel,
            metrics: [
              _Metric(
                context.l10n.averageCost,
                formatMoney(
                  context,
                  data.inventory.averageCost > 0
                      ? data.inventory.averageCost
                      : (data.part['cost_price'] as num?)?.toDouble() ?? 0,
                ),
              ),
              _Metric(
                context.l10n.stockLevel,
                '${data.inventory.totalQuantity}',
              ),
              _Metric(context.l10n.minStock, '${data.inventory.minStock}'),
              _Metric(
                context.l10n.lowStockLabel,
                data.inventory.isBelowMinStock
                    ? context.l10n.yes
                    : context.l10n.no,
                highlight: data.inventory.isBelowMinStock,
              ),
              _Metric(
                context.l10n.valueAtSell,
                formatMoney(context, data.inventory.valueAtSell),
              ),
              _Metric(
                context.l10n.valueAtCost,
                formatMoney(context, data.inventory.valueAtCost),
              ),
              _Metric(
                context.l10n.marginPerUnit,
                formatMoney(context, data.inventory.marginPerUnit),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricSection(
            title: context.l10n.salesPeriodTitle,
            metrics: [
              _Metric(
                context.l10n.unitsSold,
                '${data.sales.unitsSold}',
              ),
              _Metric(
                context.l10n.revenue,
                formatMoney(context, data.sales.revenue),
              ),
              _Metric(
                context.l10n.grossProfit,
                formatMoney(context, data.sales.grossProfit),
              ),
              _Metric(
                context.l10n.grossMargin,
                '${data.sales.grossMarginPercent.toStringAsFixed(1)}%',
              ),
              _Metric(
                context.l10n.reportInvoiceCount,
                '${data.sales.invoiceCount}',
              ),
              _Metric(
                context.l10n.estimatedCogs,
                formatMoney(context, data.sales.estimatedCogs),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final chart = _SalesByMonthChart(months: data.salesByMonth);
              final branches = _StockByBranchTable(rows: data.inventory.byBranch);
              if (wide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: chart),
                      const SizedBox(width: 16),
                      Expanded(child: branches),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  chart,
                  const SizedBox(height: 16),
                  branches,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _MetricSection(
            title: context.l10n.purchasesAndReturns,
            metrics: [
              _Metric(
                context.l10n.unitsPurchased,
                '${data.purchases.unitsPurchased}',
              ),
              _Metric(
                context.l10n.purchaseCost,
                formatMoney(context, data.purchases.cost),
              ),
              _Metric(
                context.l10n.purchaseOrderCount,
                '${data.purchases.orderCount}',
              ),
              _Metric(
                context.l10n.unitsReturned,
                '${data.returns.unitsReturned}',
              ),
              _Metric(
                context.l10n.returnsValue,
                formatMoney(context, data.returns.value),
              ),
              _Metric(
                context.l10n.reportReturnsCount,
                '${data.returns.returnCount}',
              ),
            ],
          ),
          if (data.movements.byType.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MovementsByTypeTable(types: data.movements.byType),
          ],
          if (data.movements.recent.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RecentMovementsTable(movements: data.movements.recent),
          ],
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({required this.title, required this.metrics});

  final String title;
  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final m in metrics)
                  _MetricChip(
                    label: m.label,
                    value: m.value,
                    highlight: m.highlight,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.warning.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AppColors.warning : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlight ? AppColors.warning : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _SalesByMonthChart extends StatelessWidget {
  const _SalesByMonthChart({required this.months});

  final List<PartAnalysisMonthSales> months;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Card(
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
            if (months.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  l10n.noData,
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.outline.withValues(alpha: 0.4),
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
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= months.length) {
                              return const SizedBox.shrink();
                            }
                            final label = months[i].month;
                            final short = label.length >= 7
                                ? label.substring(5)
                                : label;
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
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < months.length; i++)
                            FlSpot(i.toDouble(), months[i].revenue),
                        ],
                        isCurved: true,
                        color: scheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: scheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockByBranchTable extends StatelessWidget {
  const _StockByBranchTable({required this.rows});

  final List<PartAnalysisBranchQty> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.stockByBranch,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Text(l10n.noData)
            else
              DataTable2(
                columnSpacing: 12,
                horizontalMargin: 8,
                minWidth: 200,
                columns: [
                  DataColumn2(label: Text(l10n.branch)),
                  DataColumn2(
                    label: Text(l10n.quantity),
                    numeric: true,
                  ),
                  DataColumn2(
                    label: Text(l10n.averageCost),
                    numeric: true,
                  ),
                ],
                rows: [
                  for (final r in rows)
                    DataRow2(
                      cells: [
                        DataCell(Text(r.branchName)),
                        DataCell(Text('${r.quantity}')),
                        DataCell(
                          Text(
                            r.averageCost != null
                                ? formatMoney(context, r.averageCost)
                                : '—',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MovementsByTypeTable extends StatelessWidget {
  const _MovementsByTypeTable({required this.types});

  final List<PartAnalysisMovementType> types;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.movementsByType,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            DataTable2(
              columnSpacing: 12,
              horizontalMargin: 8,
              minWidth: 300,
              columns: [
                DataColumn2(label: Text(l10n.movementType)),
                DataColumn2(
                  label: Text(l10n.quantity),
                  numeric: true,
                ),
              ],
              rows: [
                for (final t in types)
                  DataRow2(
                    cells: [
                      DataCell(
                        Text(localizeMovementType(context, t.movementType)),
                      ),
                      DataCell(Text('${t.quantity}')),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentMovementsTable extends StatelessWidget {
  const _RecentMovementsTable({required this.movements});

  final List<PartAnalysisMovement> movements;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.recentMovements,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable2(
                columnSpacing: 16,
                horizontalMargin: 8,
                minWidth: 720,
                columns: [
                  DataColumn2(label: Text(l10n.date)),
                  DataColumn2(label: Text(l10n.movementType)),
                  DataColumn2(
                    label: Text(l10n.quantity),
                    numeric: true,
                  ),
                  DataColumn2(label: Text(l10n.branch)),
                  DataColumn2(label: Text(l10n.createdBy)),
                ],
                rows: [
                  for (final m in movements)
                    DataRow2(
                      cells: [
                        DataCell(Text(_shortDate(m.createdAt))),
                        DataCell(
                          Text(localizeMovementType(context, m.movementType)),
                        ),
                        DataCell(Text('${m.quantity}')),
                        DataCell(Text(m.branchName)),
                        DataCell(Text(m.createdByName ?? '—')),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }
}
