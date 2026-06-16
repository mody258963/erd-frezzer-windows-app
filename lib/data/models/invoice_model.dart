class InvoiceItemModel {
  const InvoiceItemModel({
    required this.partId,
    required this.quantity,
    this.unitPrice,
    this.partCode,
    this.partName,
    this.lineTotal,
    this.quantitySold,
    this.quantityReturnedCompleted = 0,
    this.quantityReturnedPending = 0,
    this.quantityAvailableForReturn,
    this.quantityRemaining,
  });

  final String partId;
  final double quantity;
  final double? unitPrice;
  final String? partCode;
  final String? partName;
  final double? lineTotal;
  final double? quantitySold;
  final double quantityReturnedCompleted;
  final double quantityReturnedPending;
  final double? quantityAvailableForReturn;
  final double? quantityRemaining;

  double get soldQty => quantitySold ?? quantity;

  double get availableForReturn =>
      quantityAvailableForReturn ??
      (quantity - quantityReturnedCompleted - quantityReturnedPending)
          .clamp(0.0, quantity);

  double get remainingQty =>
      quantityRemaining ??
      (soldQty - quantityReturnedCompleted - quantityReturnedPending);

  bool get canReturnMore => availableForReturn > 0;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num).toDouble();
    final sold = (json['quantity_sold'] as num?)?.toDouble() ?? qty;
    final completed =
        (json['quantity_returned_completed'] as num?)?.toDouble() ?? 0;
    final pending =
        (json['quantity_returned_pending'] as num?)?.toDouble() ?? 0;
    final available = json['quantity_available_for_return'] as num?;
    final remaining = json['quantity_remaining'] as num?;

    return InvoiceItemModel(
      partId: json['part_id'] as String,
      quantity: qty,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      partCode: json['part'] is Map
          ? (json['part'] as Map)['code'] as String?
          : null,
      partName: json['part'] is Map
          ? (json['part'] as Map)['name'] as String?
          : null,
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      quantitySold: sold,
      quantityReturnedCompleted: completed,
      quantityReturnedPending: pending,
      quantityAvailableForReturn: available?.toDouble(),
      quantityRemaining: remaining?.toDouble(),
    );
  }
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
    this.amountPaid,
    this.balanceDue,
    this.createdAt,
    this.items = const [],
    this.customerName,
    this.branchName,
    this.returnStatus,
    this.invoiceNumber,
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
  final double? amountPaid;
  final double? balanceDue;
  final String? createdAt;
  final List<InvoiceItemModel> items;
  final String? customerName;
  final String? branchName;
  final String? returnStatus;
  final String? invoiceNumber;

  String get displayNumber =>
      invoiceNumber ?? (id.length > 8 ? id.substring(0, 8) : id);

  /// Invoice fully returned — no further customer returns allowed.
  bool get isReturned =>
      (returnStatus ?? '').trim().toLowerCase() == 'returned';

  bool get isCancelled {
    final s = (status ?? '').toLowerCase();
    return s == 'cancelled' || s == 'canceled' || s == 'void';
  }

  bool get canCreateReturn => !isCancelled && !isReturned;

  bool get canReturnPartial =>
      canCreateReturn && items.any((i) => i.canReturnMore);

  /// Credit invoice marked paid after settlement (`is_paid` from API).
  bool get isSettled => isPaid == true;

  double get invoiceBalanceDue =>
      balanceDue ?? (isSettled ? 0 : total - (amountPaid ?? 0));

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final customer = json['customer'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;
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
      amountPaid: (json['amount_paid'] as num?)?.toDouble(),
      balanceDue: (json['balance_due'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
      customerName: customer?['name'] as String?,
      branchName: branch?['name'] as String?,
      returnStatus: json['return_status'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
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
  final double requested;
  final double available;

  factory StockFailure.fromJson(Map<String, dynamic> json) => StockFailure(
        partId: json['part_id'] as String,
        requested: (json['requested'] as num).toDouble(),
        available: (json['available'] as num).toDouble(),
      );
}
