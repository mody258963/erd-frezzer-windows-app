class CustomerWeekStatementLine {
  const CustomerWeekStatementLine({
    required this.partId,
    required this.partName,
    this.partCode,
    required this.quantity,
    required this.lineTotal,
  });

  final String partId;
  final String partName;
  final String? partCode;
  final double quantity;
  final double lineTotal;

  double get unitPrice => quantity > 0 ? lineTotal / quantity : 0;
}

class CustomerWeekStatement {
  const CustomerWeekStatement({
    required this.customerName,
    required this.weekStart,
    required this.weekEnd,
    required this.lines,
    required this.weekTotal,
    this.customerPhone,
    this.paymentsCollected,
  });

  final String customerName;
  final String? customerPhone;
  final String weekStart;
  final String weekEnd;
  final List<CustomerWeekStatementLine> lines;
  final double weekTotal;
  final double? paymentsCollected;
}
