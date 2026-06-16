class PurchaseOrderModel {
  const PurchaseOrderModel({
    required this.id,
    required this.status,
    this.receivedAt,
    this.supplierId,
    this.supplierName,
    this.branchId,
    this.description,
    this.paymentType,
  });

  final String id;
  final String status;
  final DateTime? receivedAt;
  final String? supplierId;
  final String? supplierName;
  final String? branchId;
  final String? description;
  final String? paymentType;

  bool get canReceive =>
      receivedAt == null &&
      status.toLowerCase() != 'settled' &&
      status.toLowerCase() != 'cancelled' &&
      status.toLowerCase() != 'canceled';

  bool get canCancel => status.toLowerCase() == 'pending';

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] as Map<String, dynamic>?;
    DateTime? receivedAt;
    final rawReceived = json['received_at'];
    if (rawReceived is String && rawReceived.isNotEmpty) {
      receivedAt = DateTime.tryParse(rawReceived);
    }
    return PurchaseOrderModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      receivedAt: receivedAt,
      supplierId: json['supplier_id'] as String? ?? supplier?['id'] as String?,
      supplierName: supplier?['name'] as String?,
      branchId: json['branch_id'] as String?,
      description: json['description'] as String?,
      paymentType: json['payment_type'] as String?,
    );
  }
}
