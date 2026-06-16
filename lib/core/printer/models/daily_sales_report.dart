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

  bool get isCash => paymentType.toLowerCase() == 'cash';
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
  });

  final String date;
  final String? branchName;
  final List<DailySalesReportLine> lines;
  final int invoiceCount;
  final double cashTotal;
  final double creditTotal;
  final double discountTotal;
  final double grandTotal;
}
