import '../../core/dashboard/dashboard_period.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/part_repository.dart';
import 'dashboard_summary_utils.dart';

/// Period for profit figures shown on the dashboard.
enum ProfitPeriod { daily, weekly, monthly }

/// Sales, cost, and profit for a dashboard period (day, week, or month).
class DailyProfitMetrics {
  const DailyProfitMetrics({
    required this.sales,
    required this.cost,
    this.invoiceCount = 0,
    this.estimated = false,
    this.period = ProfitPeriod.daily,
    this.customerRefunds = 0,
    this.grossRevenue = 0,
    this.periodDiscount = 0,
    this.periodGrossProfit = 0,
    this.refundProfitImpact = 0,
    this.reportedProfit,
  });

  final double sales;
  final double cost;
  final int invoiceCount;
  final bool estimated;
  final ProfitPeriod period;
  final double customerRefunds;
  final double grossRevenue;
  final double periodDiscount;
  final double periodGrossProfit;
  final double refundProfitImpact;
  /// `period_profit` from API when present.
  final double? reportedProfit;

  /// Net profit after returns — from API `period_profit` when available.
  double get profit =>
      reportedProfit ??
      (isPeriodScoped
          ? (periodGrossProfit - periodDiscount - refundProfitImpact)
              .clamp(0, double.infinity)
          : sales - cost);

  /// COGS = `period_revenue − period_gross_profit` (not revenue − profit).
  double get costOfGoods => isPeriodScoped && (grossRevenue > 0 || periodGrossProfit > 0)
      ? (grossRevenue - periodGrossProfit).clamp(0, double.infinity)
      : cost;

  double get marginPercent => sales > 0 ? (profit / sales) * 100 : 0;

  bool get isWeekly => period == ProfitPeriod.weekly;
  bool get isMonthly => period == ProfitPeriod.monthly;
  bool get isPeriodScoped => period != ProfitPeriod.daily || reportedProfit != null;
}

/// Reads period profit fields from a single `/dashboard/summary` response.
DailyProfitMetrics? profitFromSummary(
  Map<String, dynamic> summary, {
  DashboardPeriod period = DashboardPeriod.week,
}) {
  final profitPeriod = switch (period) {
    DashboardPeriod.day => ProfitPeriod.daily,
    DashboardPeriod.week => ProfitPeriod.weekly,
    DashboardPeriod.month => ProfitPeriod.monthly,
  };

  final hasPeriodProfit = summary.containsKey('period_profit') ||
      summary.containsKey('weekly_profit');

  if (hasPeriodProfit) {
    final profit = summaryPeriodNum(summary, 'profit');
    final revenue = summaryPeriodNum(summary, 'revenue');
    final refunds = summaryPeriodNum(summary, 'customer_refunds');
    final netSales = summaryPeriodNum(summary, 'net_sales');
    final discount = summaryPeriodNum(summary, 'discount');
    final grossProfit = summaryPeriodNum(summary, 'gross_profit');
    final refundImpact =
        summaryPeriodNum(summary, 'customer_refund_profit_impact');
    final salesDisplay = netSales > 0
        ? netSales
        : (revenue - refunds).clamp(0.0, double.infinity);
    final cogs = (revenue > 0 || grossProfit > 0
            ? (revenue - grossProfit).clamp(0, double.infinity)
            : 0.0)
        .toDouble();

    return DailyProfitMetrics(
      sales: salesDisplay > 0 ? salesDisplay : revenue,
      cost: cogs,
      period: profitPeriod,
      customerRefunds: refunds,
      grossRevenue: revenue,
      periodDiscount: discount,
      periodGrossProfit: grossProfit,
      refundProfitImpact: refundImpact,
      reportedProfit: profit,
    );
  }

  if (period != DashboardPeriod.day) return null;

  final sales = _num(
    summary['today_sales'] ?? summary['sales_today'] ?? summary['total_sales_today'],
  );

  for (final key in [
    'today_profit',
    'profit_today',
    'today_gross_profit',
    'gross_profit_today',
    'net_profit_today',
  ]) {
    if (summary.containsKey(key)) {
      final dayProfit = _num(summary[key]);
      return DailyProfitMetrics(
        sales: sales,
        cost: (sales - dayProfit).clamp(0, double.infinity),
        invoiceCount: _int(summary['today_invoices_count']),
      );
    }
  }

  final dayCost = _num(
    summary['today_cost'] ??
        summary['today_cogs'] ??
        summary['cost_of_goods_today'] ??
        summary['today_cost_of_goods'],
  );
  if (summary.containsKey('today_cost') ||
      summary.containsKey('today_cogs') ||
      summary.containsKey('cost_of_goods_today')) {
    return DailyProfitMetrics(
      sales: sales,
      cost: dayCost,
      invoiceCount: _int(summary['today_invoices_count']),
    );
  }

  if (sales > 0 && summary.containsKey('today_margin')) {
    final margin = _num(summary['today_margin']);
    final dayProfit = sales * (margin / 100);
    return DailyProfitMetrics(sales: sales, cost: sales - dayProfit);
  }

  return null;
}

/// Computes profit from today's invoices and catalog cost prices (fallback).
Future<DailyProfitMetrics> computeTodayProfit({
  required InvoiceRepository invoiceRepository,
  required PartRepository partRepository,
}) async {
  final today = _todayIsoDate();
  final invoices =
      await invoiceRepository.list(from: today, to: today, perPage: 100);
  final parts = await partRepository.list(perPage: 500);
  final costByPartId = {for (final p in parts) p.id: p.costPrice};

  var sales = 0.0;
  var cost = 0.0;
  var count = 0;

  for (final inv in invoices) {
    if (_isCancelled(inv)) continue;
    count++;
    final lines = inv.items;
    if (lines.isEmpty) {
      sales += inv.total;
      continue;
    }
    for (final line in lines) {
      final qty = line.quantity;
      final lineSales = line.lineTotal ?? (line.unitPrice ?? 0) * qty;
      final unitCost = costByPartId[line.partId] ?? 0;
      sales += lineSales;
      cost += unitCost * qty;
    }
  }

  return DailyProfitMetrics(
    sales: sales,
    cost: cost,
    invoiceCount: count,
    estimated: true,
  );
}

String _todayIsoDate() {
  final n = DateTime.now();
  final y = n.year.toString().padLeft(4, '0');
  final m = n.month.toString().padLeft(2, '0');
  final d = n.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

bool _isCancelled(InvoiceModel inv) {
  final s = (inv.status ?? '').toLowerCase();
  return s == 'cancelled' || s == 'canceled' || s == 'void';
}

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}
