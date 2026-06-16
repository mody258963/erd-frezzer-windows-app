import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/part_sales_chart_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/part_repository.dart';
import '../../data/repositories/report_repository.dart';
import 'daily_profit.dart';
import 'product_analysis.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.loading = false,
    this.error,
    this.summary,
    this.sales,
    this.activity = const [],
    this.inventoryAlerts = const [],
    this.receivables = const [],
    this.payables,
    this.productAnalysis = const [],
    this.dailyProfit,
    this.partsSalesChart,
  });

  final bool loading;
  final String? error;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? sales;
  final List<Map<String, dynamic>> activity;
  final List<Map<String, dynamic>> inventoryAlerts;
  final List<Map<String, dynamic>> receivables;
  final Map<String, dynamic>? payables;
  final List<ProductAnalysisItem> productAnalysis;
  final DailyProfitMetrics? dailyProfit;
  final PartSalesChartData? partsSalesChart;

  @override
  List<Object?> get props => [
        loading,
        error,
        summary,
        sales,
        activity,
        inventoryAlerts,
        receivables,
        payables,
        productAnalysis,
        dailyProfit,
        partsSalesChart,
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

  Future<void> load({String? branchId}) async {
    emit(const DashboardState(loading: true));
    try {
      final core = await Future.wait([
        _repo.summary(branchId: branchId),
        _repo.sales(branchId: branchId),
        _repo.activity(branchId: branchId),
        _repo.inventory(branchId: branchId),
        _repo.receivables(branchId: branchId),
        _repo.payables(branchId: branchId),
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

      final salesRows = salesReport.isNotEmpty
          ? salesReport
          : extractSalesProductRows(sales);

      final productAnalysis = buildProductAnalysis(
        salesRows: salesRows,
        inventoryAlerts: inventoryAlerts,
      );

      DailyProfitMetrics? dailyProfit = profitFromSummary(summary);
      if (dailyProfit == null) {
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
      ));
    } catch (e) {
      emit(DashboardState(error: e.toString()));
    }
  }
}
