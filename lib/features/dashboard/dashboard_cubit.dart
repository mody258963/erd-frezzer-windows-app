import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/dashboard/dashboard_period.dart';
import '../../data/models/dashboard_cash_model.dart';
import '../../data/models/dashboard_period_info.dart';
import '../../data/models/part_sales_chart_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/part_repository.dart';
import '../../data/repositories/report_repository.dart';
import 'daily_profit.dart';
import 'dashboard_summary_utils.dart';
import 'product_analysis.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.loading = false,
    this.error,
    this.period = DashboardPeriod.week,
    this.periodInfo,
    this.summary,
    this.sales,
    this.activity = const [],
    this.inventoryAlerts = const [],
    this.receivables = const [],
    this.payables,
    this.productAnalysis = const [],
    this.dailyProfit,
    this.partsSalesChart,
    this.cash,
  });

  final bool loading;
  final String? error;
  final DashboardPeriod period;
  final DashboardPeriodInfo? periodInfo;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? sales;
  final List<Map<String, dynamic>> activity;
  final List<Map<String, dynamic>> inventoryAlerts;
  final List<Map<String, dynamic>> receivables;
  final Map<String, dynamic>? payables;
  final List<ProductAnalysisItem> productAnalysis;
  final DailyProfitMetrics? dailyProfit;
  final PartSalesChartData? partsSalesChart;
  final DashboardCash? cash;

  @override
  List<Object?> get props => [
        loading,
        error,
        period,
        periodInfo,
        summary,
        sales,
        activity,
        inventoryAlerts,
        receivables,
        payables,
        productAnalysis,
        dailyProfit,
        partsSalesChart,
        cash,
      ];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._repo,
    this._invoices,
    this._parts,
    this._reports,
  ) : super(const DashboardState());

  final DashboardRepository _repo;
  final InvoiceRepository _invoices;
  final PartRepository _parts;
  final ReportRepository _reports;

  Future<void> load({
    String? branchId,
    DashboardPeriod? period,
    DateTime? anchorDate,
  }) async {
    final effectivePeriod = period ?? state.period;
    final effectiveAnchor = anchorDate ?? DateTime.now();
    emit(DashboardState(
      loading: true,
      period: effectivePeriod,
    ));
    try {
      final core = await Future.wait([
        _repo.summary(
          branchId: branchId,
          period: effectivePeriod,
          anchorDate: effectiveAnchor,
        ),
        _repo.sales(
          branchId: branchId,
          period: effectivePeriod,
          anchorDate: effectiveAnchor,
        ),
        _repo.activity(branchId: branchId),
        _repo.inventory(branchId: branchId),
        _repo.receivables(branchId: branchId),
        _loadPayables(branchId),
      ]);

      List<Map<String, dynamic>> salesReport = [];
      try {
        salesReport = await _repo.productSales(branchId: branchId);
      } catch (_) {
        // Product breakdown is optional if reports endpoint is unavailable.
      }

      final summary = core[0] as Map<String, dynamic>;
      final sales = core[1] as Map<String, dynamic>;
      final activity = core[2] as List<Map<String, dynamic>>;
      final inventoryAlerts = core[3] as List<Map<String, dynamic>>;
      final receivables = core[4] as List<Map<String, dynamic>>;
      final payables = core[5] as Map<String, dynamic>;

      final periodInfo = DashboardPeriodInfo.fromJson(
        summary['period'] ?? sales['period'],
      );

      if (kDebugMode && periodInfo.key != effectivePeriod) {
        debugPrint(
          'Dashboard period mismatch: requested ${effectivePeriod.name}, '
          'API returned ${periodInfo.key.name}',
        );
      }

      Map<String, dynamic>? cashRaw;
      try {
        cashRaw = await _repo.cash(
          branchId: branchId,
          period: effectivePeriod,
          anchorDate: effectiveAnchor,
        );
        final cashPeriod = DashboardPeriodInfo.fromJson(cashRaw['period']);
        if (cashPeriod.key != effectivePeriod) {
          if (kDebugMode) {
            debugPrint(
              'Ignoring cash response: period ${cashPeriod.key.name} '
              '!= ${effectivePeriod.name}',
            );
          }
          cashRaw = null;
        }
      } catch (_) {
        // Cash endpoint is optional; summary may include realized fields.
      }
      final cash = DashboardCash.fromResponses(
        summary: summary,
        cashEndpoint: cashRaw,
      );

      if (kDebugMode) {
        assert(
          cash.cashFlowConsistent || !cash.hasPeriodCashFlow,
          'Cash flow inconsistent: in=${cash.periodCashInRealized} '
          'out=${cash.periodCashOutRealized} net=${cash.periodNetCashFlowRealized}',
        );
        assert(
          summaryNetCashFlowConsistent(summary) ||
              !summary.containsKey('period_net_cash_flow_realized'),
          'Summary cash flow inconsistent',
        );
        assert(
          summaryProfitConsistent(summary) ||
              !summary.containsKey('period_profit'),
          'Summary profit inconsistent',
        );
      }

      final salesRows = salesReport.isNotEmpty
          ? salesReport
          : extractSalesProductRows(sales);

      final productAnalysis = buildProductAnalysis(
        salesRows: salesRows,
        inventoryAlerts: inventoryAlerts,
      );

      DailyProfitMetrics? dailyProfit = profitFromSummary(
        summary,
        period: effectivePeriod,
      );
      if (dailyProfit == null && effectivePeriod == DashboardPeriod.day) {
        try {
          dailyProfit = await computeTodayProfit(
            invoiceRepository: _invoices,
            partRepository: _parts,
          );
        } catch (_) {
          // Profit is optional if invoices or parts API is unavailable.
        }
      }

      PartSalesChartData? partsSalesChart;
      try {
        final chartRaw = await _reports.partsSalesChart(
          year: DateTime.now().year,
          limit: 5,
          rankBy: 'units',
          branchId: branchId,
        );
        partsSalesChart = PartSalesChartData.fromJson(chartRaw);
      } catch (_) {
        // Yearly parts chart is optional.
      }

      emit(DashboardState(
        summary: summary,
        sales: sales,
        activity: activity,
        inventoryAlerts: inventoryAlerts,
        receivables: receivables,
        payables: payables,
        productAnalysis: productAnalysis,
        dailyProfit: dailyProfit,
        partsSalesChart: partsSalesChart,
        cash: cash.hasData ? cash : null,
        period: effectivePeriod,
        periodInfo: periodInfo,
      ));
    } catch (e) {
       emit(DashboardState(
        error: e.toString(),
        period: effectivePeriod,
      ));
    }
  }

  void setPeriod(DashboardPeriod period, {String? branchId}) {
    load(branchId: branchId, period: period);
  }

  Future<Map<String, dynamic>> _loadPayables(String? branchId) async {
    try {
      final grouped = await _repo.payablesBySupplier(branchId: branchId);
      final map = grouped.toPayablesMap();
      try {
        final legacy = await _repo.payables(branchId: branchId);
        for (final key in [
          'overdue_installments',
          'upcoming_installments',
          'overdue',
          'upcoming',
        ]) {
          if (legacy[key] != null) map[key] = legacy[key];
        }
      } catch (_) {}
      return map;
    } catch (_) {
      return _repo.payables(branchId: branchId);
    }
  }
}
