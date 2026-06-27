import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/role_context.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/branch/branch_filter_scope.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/part_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../core/dashboard/dashboard_period.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/loading_error.dart';
import '../shared/page_scaffold.dart';
import '../shared/status_chip.dart';
import 'dashboard_cubit.dart';
import 'dashboard_period_labels.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/dashboard_finance_hub.dart';
import 'widgets/dashboard_kpi_grid.dart';
import 'widgets/dashboard_section.dart';
import 'widgets/parts_sales_chart_panel.dart';
import 'widgets/product_ranking.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final branchId = apiBranchIdFromContext(context);

    return BlocProvider(
      create: (_) => DashboardCubit(
            getIt<DashboardRepository>(),
            getIt<InvoiceRepository>(),
            getIt<PartRepository>(),
            getIt<ReportRepository>(),
          )..load(branchId: branchId),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  @override
  void initState() {
    super.initState();
    getIt<AppRefreshBus>().addListener(_onRefresh);
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh(AppRefreshKind kind) {
    if (!mounted) return;
    if (kind != AppRefreshKind.dashboard &&
        kind != AppRefreshKind.branchFilter &&
        kind != AppRefreshKind.settlements) {
      return;
    }
    context.read<DashboardCubit>().load(
          branchId: apiBranchIdFromContext(context),
          period: context.read<DashboardCubit>().state.period,
        );
  }

  Future<void> _reloadDashboard() async {
    await context.read<DashboardCubit>().load(
          branchId: apiBranchIdFromContext(context),
          period: context.read<DashboardCubit>().state.period,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.loading) {
          return LoadingView(message: context.l10n.loadingDashboard);
        }
        if (state.error != null) {
          return ErrorView(
            message: state.error!,
            onRetry: _reloadDashboard,
          );
        }

        final l10n = context.l10n;
        final summary = state.summary ?? {};
        final sales = state.sales ?? {};
        final points = (sales['points'] as List<dynamic>?) ?? [];
        final scheme = Theme.of(context).colorScheme;

        final periodRange = dashboardPeriodRangeLabel(context, state.periodInfo);

        Future<void> refreshDashboard() => _reloadDashboard();

        return PageScaffold(
          scrollable: false,
          title: l10n.dashboardTitle,
          subtitle: periodRange ?? l10n.dashboardSubtitle,
          actions: [
            if (context.canPerform(AppAction.invoiceCreate))
              FilledButton.tonalIcon(
                onPressed: () => context.go(RoutePaths.pos),
                icon: const Icon(Icons.point_of_sale, size: 18),
                label: Text(l10n.openPos),
              ),
            if (context.canPerform(AppAction.invoiceCreate))
              const SizedBox(width: 8),
            IconButton(
              onPressed: refreshDashboard,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.tryAgain,
            ),
          ],
          child: RefreshIndicator(
            onRefresh: refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 960;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DashboardPeriodFilter(
                        period: state.period,
                        onChanged: (period) => context
                            .read<DashboardCubit>()
                            .setPeriod(
                              period,
                              branchId: apiBranchIdFromContext(context),
                            ),
                      ),
                      const SizedBox(height: 16),
                      DashboardKpiGrid(
                        summary: summary,
                        period: state.period,
                        dailyProfit: state.dailyProfit,
                      ),
                      const SizedBox(height: 16),
                      DashboardFinanceHub(
                        summary: summary,
                        cash: state.cash,
                        receivables: state.receivables,
                        payables: state.payables,
                        period: state.period,
                      ),
                      const SizedBox(height: 16),
                      PartsSalesChartPanel(data: state.partsSalesChart),
                      const SizedBox(height: 16),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _SalesTrendCard(
                                    points: points,
                                    scheme: scheme,
                                  ),
                                  const SizedBox(height: 16),
                                  ProductRankingPanel(
                                    products: state.productAnalysis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _ActivityCard(activity: state.activity),
                            ),
                          ],
                        )
                      else ...[
                        _SalesTrendCard(points: points, scheme: scheme),
                        const SizedBox(height: 16),
                        ProductRankingPanel(
                          products: state.productAnalysis,
                        ),
                        const SizedBox(height: 16),
                        _ActivityCard(activity: state.activity),
                      ],
                      const SizedBox(height: 24),
                      if (state.inventoryAlerts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        DashboardSection(
                          title: l10n.inventoryAlertsTitle,
                          subtitle: l10n.dashboardNeedsAttention,
                          trailing: TextButton(
                            onPressed: () =>
                                context.go('${RoutePaths.parts}?tab=stock'),
                            child: Text(l10n.viewInventory),
                          ),
                          child: Card(
                            child: Column(
                              children: [
                                for (final item
                                    in state.inventoryAlerts.take(6))
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.warning
                                          .withValues(alpha: 0.15),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.warning,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      '${item['part_code'] ?? item['code'] ?? ''} — ${item['part_name'] ?? item['name'] ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      l10n.branchRowLabel(
                                        '${item['branch_name'] ?? item['branch_id'] ?? ''}',
                                      ),
                                    ),
                                    trailing: StatusChip(
                                      label: l10n.qtyRowLabel(
                                        '${item['quantity'] ?? item['qty'] ?? ''}',
                                      ),
                                      variant: StatusChipVariant.warning,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardPeriodFilter extends StatelessWidget {
  const _DashboardPeriodFilter({
    required this.period,
    required this.onChanged,
  });

  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<DashboardPeriod>(
      segments: [
        ButtonSegment(
          value: DashboardPeriod.day,
          label: Text(l10n.dashboardPeriodToday),
          icon: const Icon(Icons.today_outlined, size: 18),
        ),
        ButtonSegment(
          value: DashboardPeriod.week,
          label: Text(l10n.dashboardPeriodWeek),
          icon: const Icon(Icons.date_range_outlined, size: 18),
        ),
        ButtonSegment(
          value: DashboardPeriod.month,
          label: Text(l10n.dashboardPeriodMonth),
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
        ),
      ],
      selected: {period},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  const _SalesTrendCard({
    required this.points,
    required this.scheme,
  });

  final List<dynamic> points;
  final ColorScheme scheme;

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
              l10n.salesTrend,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  l10n.noData,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.outline.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(
                              i.toDouble(),
                              ((points[i] as Map)['total'] as num?)
                                      ?.toDouble() ??
                                  0,
                            ),
                        ],
                        isCurved: true,
                        color: scheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.primary.withValues(alpha: 0.2),
                              scheme.primary.withValues(alpha: 0.02),
                            ],
                          ),
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final List<Map<String, dynamic>> activity;

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
              l10n.activityLogTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.activityLogSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ActivityTimeline(items: activity),
          ],
        ),
      ),
    );
  }
}
