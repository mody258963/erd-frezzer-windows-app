class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.address,
    this.creditLimit = 0,
    this.outstandingBalance = 0,
    this.isActive = true,
    this.linkedSupplierId,
    this.linkedSupplierName,
    this.settlementCycle,
    this.lastSettledAt,
    this.branchId,
  });

  final String id;
  final String name;
  final String type;
  final String? phone;
  final String? address;
  final double creditLimit;
  final double outstandingBalance;
  final bool isActive;
  final String? linkedSupplierId;
  final String? linkedSupplierName;
  /// `daily` | `weekly` for credit customers; null for cash.
  final String? settlementCycle;
  final DateTime? lastSettledAt;
  final String? branchId;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final linked = json['linked_supplier'] as Map<String, dynamic>?;
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      outstandingBalance:
          (json['outstanding_balance'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      linkedSupplierId:
          json['linked_supplier_id'] as String? ?? linked?['id'] as String?,
      linkedSupplierName: linked?['name'] as String?,
      settlementCycle: json['settlement_cycle'] as String?,
      lastSettledAt: json['last_settled_at'] != null
          ? DateTime.tryParse(json['last_settled_at'] as String)
          : null,
      branchId: json['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeLink = false}) => {
        'name': name,
        'type': type,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (type == 'credit') ...{
          'credit_limit': creditLimit,
          'settlement_cycle': settlementCycle ?? 'weekly',
        },
        'is_active': isActive,
        if (includeLink) 'linked_supplier_id': linkedSupplierId,
      };
}
