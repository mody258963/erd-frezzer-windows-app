import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/l10n/report_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/branch_model.dart';
import '../../data/repositories/report_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/branch_dropdown.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({required this.kind, super.key});

  final ReportKind kind;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  List<Map<String, dynamic>>? _rows;
  Map<String, dynamic>? _summary;
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
    if (_isDateFiltered) {
      _loadBranches();
    }
  }

  bool get _isDateFiltered =>
      widget.kind == ReportKind.sales || widget.kind == ReportKind.returns;

  bool get _isReturnsSummary => widget.kind == ReportKind.returns;

  String get _title => switch (widget.kind) {
        ReportKind.sales => context.l10n.salesReportTitle,
        ReportKind.inventory => context.l10n.inventoryReportTitle,
        ReportKind.customers => context.l10n.customersReportTitle,
        ReportKind.suppliers => context.l10n.suppliersReportTitle,
        ReportKind.returns => context.l10n.returnsReportTitle,
      };

  Future<void> _loadBranches() async {
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = getIt<ReportRepository>();
      final from = _isoDate(_range.start);
      final to = _isoDate(_range.end);

      if (_isReturnsSummary) {
        final data = await repo.returns(from: from, to: to);
        setState(() {
          _summary = data;
          _rows = null;
          _loading = false;
          _loaded = true;
        });
        return;
      }

      final List<Map<String, dynamic>> raw = switch (widget.kind) {
        ReportKind.sales => await repo.sales(
            from: from,
            to: to,
            branchId: _branchId,
          ),
        ReportKind.inventory => await repo.inventory(),
        ReportKind.customers => await repo.customers(),
        ReportKind.suppliers => await repo.suppliers(),
        ReportKind.returns => [],
      };

      setState(() {
        _rows = flattenReportRows(context, widget.kind, raw);
        _summary = _computeTotals(raw);
        _loading = false;
        _loaded = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loaded = true;
      });
    }
  }

  Map<String, dynamic>? _computeTotals(List<Map<String, dynamic>> raw) {
    if (widget.kind == ReportKind.sales) {
      var total = 0.0;
      for (final r in raw) {
        total += (r['total'] as num?)?.toDouble() ?? 0;
      }
      return {'invoice_count': raw.length, 'total_sales': total};
    }
    if (widget.kind == ReportKind.inventory) {
      var cost = 0.0;
      var sell = 0.0;
      for (final r in raw) {
        cost += (r['value_cost'] as num?)?.toDouble() ?? 0;
        sell += (r['value_sell'] as num?)?.toDouble() ?? 0;
      }
      return {'value_cost': cost, 'value_sell': sell};
    }
    return null;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final desc = reportDescription(context, widget.kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: _title,
          subtitle: desc,
          actions: [
            TextButton.icon(
              onPressed: () => context.go(RoutePaths.reports),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.backToReports),
            ),
            if (_loaded)
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.tryAgain,
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isDateFiltered) ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(
                            l10n.reportDateRange(
                              _isoDate(_range.start),
                              _isoDate(_range.end),
                            ),
                          ),
                        ),
                        if (widget.kind == ReportKind.sales &&
                            _branches.isNotEmpty)
                          SizedBox(
                            width: 260,
                            child: BranchDropdown(
                              branches: _branches,
                              value: _branchId,
                              label: l10n.branch,
                              onChanged: (v) => setState(() => _branchId = v),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics_outlined),
                    label: Text(l10n.runReport),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: !_loaded
              ? Center(
                  child: Text(
                    l10n.reportTapRun,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
              : _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _isReturnsSummary
                          ? _buildReturnsSummary(context)
                          : _buildTable(context),
        ),
      ],
    );
  }

  Widget _buildReturnsSummary(BuildContext context) {
    final l10n = context.l10n;
    final data = _summary ?? {};
    final byReason = (data['by_reason'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: l10n.reportReturnsCount,
                value: '${data['total_count'] ?? 0}',
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: l10n.reportReturnsValue,
                value: formatMoney(
                  context,
                  (data['total_value'] as num?)?.toDouble(),
                ),
                icon: Icons.payments_outlined,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.reportByReason,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (byReason.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.noData)),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: byReason.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = byReason[i] as Map;
                return ListTile(
                  title: Text('${row['reason'] ?? l10n.reason}'),
                  trailing: Text(
                    l10n.reportReasonCount('${row['count'] ?? 0}'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    final l10n = context.l10n;
    final rows = _rows ?? [];

    if (rows.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    final columns = rows.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_summary != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTotalsBanner(context),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.reportRowCount('${rows.length}'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: DataTable2(
                headingRowHeight: 48,
                dataRowHeight: 52,
                columnSpacing: 16,
                horizontalMargin: 16,
                minWidth: 900,
                columns: [
                  for (final key in columns)
                    DataColumn2(
                      label: Text(
                        reportColumnLabel(context, key),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
                rows: [
                  for (final row in rows)
                    DataRow2(
                      cells: [
                        for (final key in columns)
                          DataCell(
                            Text(
                              formatReportCell(context, key, row[key]),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsBanner(BuildContext context) {
    final l10n = context.l10n;
    final s = _summary!;

    if (widget.kind == ReportKind.sales) {
      return Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: l10n.reportInvoiceCount,
              value: '${s['invoice_count'] ?? 0}',
              icon: Icons.receipt,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryTile(
              label: l10n.reportTotalSales,
              value: formatMoney(context, s['total_sales'] as num?),
              icon: Icons.trending_up,
              color: AppColors.success,
            ),
          ),
        ],
      );
    }

    if (widget.kind == ReportKind.inventory) {
      return Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: l10n.colValueCost,
              value: formatMoney(context, s['value_cost'] as num?),
              icon: Icons.shopping_bag_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryTile(
              label: l10n.colValueSell,
              value: formatMoney(context, s['value_sell'] as num?),
              icon: Icons.sell_outlined,
              color: AppColors.success,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Route entry points -----------------------------------------------------------

class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ReportDetailScreen(kind: ReportKind.sales);
}

class InventoryReportScreen extends StatelessWidget {
  const InventoryReportScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ReportDetailScreen(kind: ReportKind.inventory);
}

class CustomersReportScreen extends StatelessWidget {
  const CustomersReportScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ReportDetailScreen(kind: ReportKind.customers);
}

class SuppliersReportScreen extends StatelessWidget {
  const SuppliersReportScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ReportDetailScreen(kind: ReportKind.suppliers);
}

class ReturnsReportScreen extends StatelessWidget {
  const ReturnsReportScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ReportDetailScreen(kind: ReportKind.returns);
}
