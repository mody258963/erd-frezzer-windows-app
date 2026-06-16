class LinkedBalanceModel {
  const LinkedBalanceModel({
    required this.isLinked,
    this.customerBalance = 0,
    this.supplierDebt = 0,
    this.netAmount = 0,
    this.netDirection = 'balanced',
    this.maxOffsetAmount = 0,
    this.customerName,
    this.supplierName,
    this.customerId,
    this.supplierId,
  });

  final bool isLinked;
  final double customerBalance;
  final double supplierDebt;
  final double netAmount;
  final String netDirection;
  final double maxOffsetAmount;
  final String? customerName;
  final String? supplierName;
  final String? customerId;
  final String? supplierId;

  factory LinkedBalanceModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final supplier = json['supplier'] as Map<String, dynamic>?;
    return LinkedBalanceModel(
      isLinked: json['is_linked'] as bool? ?? false,
      customerBalance: _num(
        json['customer_balance'] ?? customer?['outstanding_balance'],
      ),
      supplierDebt: _num(json['supplier_debt'] ?? supplier?['total_debt']),
      netAmount: _num(json['net_amount']),
      netDirection: json['net_direction'] as String? ?? 'balanced',
      maxOffsetAmount: _num(json['max_offset_amount']),
      customerName: customer?['name'] as String?,
      supplierName: supplier?['name'] as String?,
      customerId: customer?['id'] as String? ?? json['customer_id'] as String?,
      supplierId: supplier?['id'] as String? ?? json['supplier_id'] as String?,
    );
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
