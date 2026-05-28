class InvoiceItemModel {
  const InvoiceItemModel({
    required this.partId,
    required this.quantity,
    this.unitPrice,
    this.partCode,
    this.partName,
    this.lineTotal,
  });

  final String partId;
  final int quantity;
  final double? unitPrice;
  final String? partCode;
  final String? partName;
  final double? lineTotal;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) =>
      InvoiceItemModel(
        partId: json['part_id'] as String,
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unit_price'] as num?)?.toDouble(),
        partCode: json['part'] is Map
            ? (json['part'] as Map)['code'] as String?
            : null,
        partName: json['part'] is Map
            ? (json['part'] as Map)['name'] as String?
            : null,
        lineTotal: (json['line_total'] as num?)?.toDouble(),
      );
}

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.customerId,
    required this.branchId,
    required this.paymentType,
    required this.total,
    this.discount = 0,
    this.subtotal = 0,
    this.status,
    this.isPaid,
    this.createdAt,
    this.items = const [],
    this.customerName,
  });

  final String id;
  final String customerId;
  final String branchId;
  final String paymentType;
  final double total;
  final double discount;
  final double subtotal;
  final String? status;
  final bool? isPaid;
  final String? createdAt;
  final List<InvoiceItemModel> items;
  final String? customerName;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final customer = json['customer'] as Map<String, dynamic>?;
    return InvoiceModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      branchId: json['branch_id'] as String,
      paymentType: json['payment_type'] as String,
      total: (json['total'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String?,
      isPaid: json['is_paid'] as bool?,
      createdAt: json['created_at'] as String?,
      customerName: customer?['name'] as String?,
      items: itemsJson
          .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StockFailure {
  const StockFailure({
    required this.partId,
    required this.requested,
    required this.available,
  });

  final String partId;
  final int requested;
  final int available;

  factory StockFailure.fromJson(Map<String, dynamic> json) => StockFailure(
        partId: json['part_id'] as String,
        requested: (json['requested'] as num).toInt(),
        available: (json['available'] as num).toInt(),
      );
}
