import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/part_repository.dart';

/// Period for profit figures shown on the dashboard.
enum ProfitPeriod { daily, weekly }

/// Sales, cost, and profit for a dashboard period (day or week).
class DailyProfitMetrics {
  const DailyProfitMetrics({
    required this.sales,
    required this.cost,
    this.invoiceCount = 0,
    this.estimated = false,
    this.period = ProfitPeriod.daily,
    this.customerRefunds = 0,
    this.grossRevenue = 0,
    this.weeklyDiscount = 0,
    this.weeklyGrossProfit = 0,
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
  final double weeklyDiscount;
  final double weeklyGrossProfit;
  final double refundProfitImpact;
  /// `weekly_profit` from API when present.
  final double? reportedProfit;

  /// Net profit after returns — always from API when weekly summary exists.
  double get profit =>
      reportedProfit ??
      (isWeekly ? weeklyGrossProfit - weeklyDiscount : sales - cost);

  double get marginPercent => sales > 0 ? (profit / sales) * 100 : 0;

  bool get isWeekly => period == ProfitPeriod.weekly;
}

/// Reads profit fields returned by `/dashboard/summary` when present.
DailyProfitMetrics? profitFromSummary(Map<String, dynamic> summary) {
  if (summary.containsKey('weekly_profit')) {
    final profit = _num(summary['weekly_profit']);
    final revenue = _num(summary['weekly_revenue']);
    final refunds = _num(summary['weekly_customer_refunds']);
    final netSales = _num(summary['weekly_net_sales']);
    final discount = _num(summary['weekly_discount']);
    final grossProfit = _num(summary['weekly_gross_profit']);
    final refundImpact = _num(summary['weekly_customer_refund_profit_impact']);
    final salesDisplay = netSales > 0
        ? netSales
        : (revenue - refunds).clamp(0.0, double.infinity);
    return DailyProfitMetrics(
      sales: salesDisplay > 0 ? salesDisplay : revenue,
      cost: salesDisplay > 0
          ? (salesDisplay - profit).clamp(0, double.infinity)
          : 0,
      period: ProfitPeriod.weekly,
      customerRefunds: refunds,
      grossRevenue: revenue,
      weeklyDiscount: discount,
      weeklyGrossProfit: grossProfit,
      refundProfitImpact: refundImpact,
      reportedProfit: profit,
    );
  }

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
      final profit = _num(summary[key]);
      return DailyProfitMetrics(
        sales: sales,
        cost: (sales - profit).clamp(0, double.infinity),
        invoiceCount: _int(summary['today_invoices_count']),
      );
    }
  }

  final cost = _num(
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
      cost: cost,
      invoiceCount: _int(summary['today_invoices_count']),
    );
  }

  if (sales > 0 && summary.containsKey('today_margin')) {
    final margin = _num(summary['today_margin']);
    final profit = sales * (margin / 100);
    return DailyProfitMetrics(sales: sales, cost: sales - profit);
  }

  return null;
}

/// Computes profit from today's invoices and catalog cost prices.
Future<DailyProfitMetrics> computeTodayProfit({
  required InvoiceRepository invoiceRepository,
  required PartRepository partRepository,
}) async {
  final today = _todayIsoDate();
  final invoices = await invoiceRepository.list(from: today, to: today, perPage: 200);
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
      final lineSales =
          line.lineTotal ?? (line.unitPrice ?? 0) * qty;
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
