import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/branch/branch_filter_scope.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/capital_model.dart';
import '../../data/repositories/report_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/branch_dropdown.dart';
import '../shared/financing_snapshot_panel.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

/// P&amp;L from `GET /reports/financial`.
class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;
  bool _loaded = false;

  late DateTimeRange _range;
  List<BranchModel> _branches = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    getIt<AppRefreshBus>().addListener(_onAppRefresh);
    _loadBranchNames();
  }

  Future<void> _loadBranchNames() async {
    try {
      final branches = await loadActiveBranches();
      if (mounted) setState(() => _branches = branches);
    } catch (_) {}
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onAppRefresh);
    super.dispose();
  }

  void _onAppRefresh(AppRefreshKind kind) {
    if (!mounted || kind != AppRefreshKind.branchFilter || !_loaded) return;
    _load();
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
      final data = await getIt<ReportRepository>().financial(
        from: _isoDate(_range.start),
        to: _isoDate(_range.end),
        branchId: apiBranchIdFromContext(context),
      );
      setState(() {
        _data = data;
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.financialReportTitle,
          subtitle: l10n.reportDescFinancial,
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
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
                    ],
                  ),
                  const SizedBox(height: 12),
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
                      : _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final data = _data ?? {};
    final totals = (data['totals'] as Map<String, dynamic>?) ?? {};
    final returns = (data['returns'] as Map<String, dynamic>?) ?? {};
    final capital = (data['capital'] as Map<String, dynamic>?) ?? {};
    final byBranch = (data['by_branch'] as List<dynamic>?) ?? [];
    final names = branchNameById(_branches);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (capital.isNotEmpty) ...[
          Text(
            l10n.businessCapitalTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          FinancingSnapshotPanel(
            snapshot: FinancingSnapshot.fromJson(capital),
            capitalAmount: capital['capital_amount'] is num
                ? (capital['capital_amount'] as num).toDouble()
                : double.tryParse('${capital['capital_amount']}'),
            currency: '${capital['capital_currency'] ?? capital['currency'] ?? 'EGP'}',
          ),
          const SizedBox(height: 20),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryTile(
              label: l10n.colRevenue,
              value: formatMoney(context, totals['revenue']),
              icon: Icons.point_of_sale_outlined,
              color: AppColors.primary,
            ),
            _SummaryTile(
              label: l10n.colDiscount,
              value: formatMoney(context, totals['discount']),
              icon: Icons.discount_outlined,
              color: AppColors.warning,
            ),
            _SummaryTile(
              label: l10n.weeklyCustomerRefunds,
              value: formatMoney(context, totals['customer_refunds']),
              icon: Icons.undo_outlined,
              color: AppColors.error,
            ),
            _SummaryTile(
              label: l10n.weeklyNetSales,
              value: formatMoney(context, totals['net_sales']),
              icon: Icons.trending_up_outlined,
              color: AppColors.secondary,
            ),
            _SummaryTile(
              label: l10n.colGrossProfit,
              value: formatMoney(context, totals['gross_profit']),
              icon: Icons.show_chart_outlined,
              color: AppColors.tertiary,
            ),
            if ((totals['customer_refund_profit_impact'] as num?)?.toDouble() !=
                    null &&
                (totals['customer_refund_profit_impact'] as num) > 0)
              _SummaryTile(
                label: l10n.refundProfitImpact,
                value: formatMoney(
                  context,
                  totals['customer_refund_profit_impact'],
                ),
                icon: Icons.trending_down_outlined,
                color: AppColors.warning,
              ),
            _SummaryTile(
              label: l10n.weeklyProfit,
              value: formatMoney(context, totals['profit']),
              icon: Icons.paid_outlined,
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.financialReturnsSection,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: l10n.financialCustomerReturns,
                value:
                    '${returns['customer_count'] ?? 0} · ${formatMoney(context, returns['customer_value'])}',
                icon: Icons.person_outline,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: l10n.financialSupplierReturns,
                value:
                    '${returns['supplier_count'] ?? 0} · ${formatMoney(context, returns['supplier_value'])}',
                icon: Icons.local_shipping_outlined,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        if (byBranch.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.financialByBranch,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable2(
                columnSpacing: 16,
                horizontalMargin: 16,
                minWidth: 900,
                columns: [
                  DataColumn2(label: Text(l10n.colBranchName)),
                  DataColumn2(label: Text(l10n.colRevenue), numeric: true),
                  DataColumn2(label: Text(l10n.colDiscount), numeric: true),
                  DataColumn2(
                    label: Text(l10n.weeklyCustomerRefunds),
                    numeric: true,
                  ),
                  DataColumn2(label: Text(l10n.colGrossProfit), numeric: true),
                  DataColumn2(label: Text(l10n.weeklyProfit), numeric: true),
                ],
                rows: [
                  for (final row in byBranch)
                    if (row is Map<String, dynamic>)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(
                              row['name'] as String? ??
                                  resolveBranchName(
                                    names,
                                    row['branch_id'],
                                    row: row,
                                  ),
                            ),
                          ),
                          DataCell(Text(
                            formatMoney(context, row['revenue']),
                          )),
                          DataCell(Text(
                            formatMoney(context, row['discount']),
                          )),
                          DataCell(Text(
                            formatMoney(
                              context,
                              row['customer_refunds'],
                            ),
                          )),
                          DataCell(Text(
                            formatMoney(context, row['gross_profit']),
                          )),
                          DataCell(Text(
                            formatMoney(context, row['profit']),
                          )),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.financialReturnsApprovalNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
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
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
