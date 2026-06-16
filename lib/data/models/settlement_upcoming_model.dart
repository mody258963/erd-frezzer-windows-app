class SettlementUpcomingRow {
  const SettlementUpcomingRow({
    required this.customerId,
    required this.customerName,
    required this.amountDue,
    required this.settlementCycle,
  });

  final String customerId;
  final String customerName;
  final double amountDue;
  final String settlementCycle;

  factory SettlementUpcomingRow.fromJson(Map<String, dynamic> json) {
    return SettlementUpcomingRow(
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0,
      settlementCycle: json['settlement_cycle'] as String? ?? 'weekly',
    );
  }
}
