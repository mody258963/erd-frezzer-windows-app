class SupplierInstallmentModel {
  const SupplierInstallmentModel({
    required this.id,
    required this.isPaid,
    required this.amount,
    this.amountPaid = 0,
    this.balanceDue,
    this.installmentNo = 0,
    this.dueDate,
    this.status,
    this.supplierName,
    this.purchaseOrderId,
  });

  final String id;
  final bool isPaid;
  final double amount;
  final double amountPaid;
  final double? balanceDue;
  final int installmentNo;
  final String? dueDate;
  final String? status;
  final String? supplierName;
  final String? purchaseOrderId;

  double get remainingBalance {
    if (balanceDue != null) return balanceDue!.clamp(0, double.infinity);
    return (amount - amountPaid).clamp(0, double.infinity);
  }

  bool get canPay => !isPaid && remainingBalance > 0;

  factory SupplierInstallmentModel.fromJson(Map<String, dynamic> json) {
    final purchase = json['purchase'] as Map<String, dynamic>?;
    final supplier = json['supplier'] as Map<String, dynamic>? ??
        (purchase?['supplier'] as Map<String, dynamic>?);
    final amount = (json['amount'] as num).toDouble();
    final paid = (json['amount_paid'] as num?)?.toDouble() ?? 0;
    final due = json['balance_due'] as num?;

    return SupplierInstallmentModel(
      id: json['id'] as String,
      isPaid: json['is_paid'] == true,
      amount: amount,
      amountPaid: paid,
      balanceDue: due?.toDouble(),
      installmentNo: (json['installment_no'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String?,
      supplierName: supplier?['name'] as String?,
      purchaseOrderId:
          purchase?['id'] as String? ?? json['purchase_id'] as String?,
    );
  }
}
