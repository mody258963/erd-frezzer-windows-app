import '../../../core/utils/payment_type.dart';

class DailySalesReportLine {
  const DailySalesReportLine({
    required this.invoiceNumber,
    required this.time,
    required this.customerName,
    required this.paymentType,
    required this.total,
    this.discount = 0,
    this.pending = false,
  });

  final String invoiceNumber;
  final String time;
  final String customerName;
  final String paymentType;
  final double total;
  final double discount;
  final bool pending;

  bool get isCash => isCashPaymentType(paymentType);
}

class DailyDrawerLine {
  const DailyDrawerLine({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;
}

class DailySalesReport {
  const DailySalesReport({
    required this.date,
    required this.lines,
    required this.invoiceCount,
    required this.cashTotal,
    required this.creditTotal,
    required this.discountTotal,
    required this.grandTotal,
    this.branchName,
    this.cashSalesTotal = 0,
    this.collections = const [],
    this.outflows = const [],
    this.cashInTotal = 0,
    this.cashOutTotal = 0,
    this.drawerTotal = 0,
    this.collectionsDetailUnavailable = false,
  });

  final String date;
  final String? branchName;
  final List<DailySalesReportLine> lines;
  final int invoiceCount;
  final double cashTotal;
  final double creditTotal;
  final double discountTotal;
  final double grandTotal;

  /// Drawer report fields (hybrid: line items + dashboard totals).
  final double cashSalesTotal;
  final List<DailyDrawerLine> collections;
  final List<DailyDrawerLine> outflows;
  final double cashInTotal;
  final double cashOutTotal;
  final double drawerTotal;
  final bool collectionsDetailUnavailable;

  double get collectionsTotal =>
      collections.fold(0.0, (sum, line) => sum + line.amount);

  double get outflowsTotal => outflows.fold(0.0, (sum, line) => sum + line.amount);

  double get computedDrawerTotal =>
      cashSalesTotal + collectionsTotal - outflowsTotal;
}
