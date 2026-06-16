/// Print payload from `GET /invoices/{id}/receipt`.
class InvoiceReceiptModel {
  const InvoiceReceiptModel({
    required this.invoice,
    required this.items,
    required this.returns,
    required this.summary,
  });

  final InvoiceReceiptHeader invoice;
  final List<InvoiceReceiptLine> items;
  final List<InvoiceReceiptReturn> returns;
  final InvoiceReceiptSummary summary;

  factory InvoiceReceiptModel.fromJson(Map<String, dynamic> json) {
    final inv = json['invoice'] as Map<String, dynamic>? ?? {};
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final returnsJson = json['returns'] as List<dynamic>? ?? [];
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};

    return InvoiceReceiptModel(
      invoice: InvoiceReceiptHeader.fromJson(inv),
      items: itemsJson
          .whereType<Map>()
          .map((e) => InvoiceReceiptLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      returns: returnsJson
          .whereType<Map>()
          .map((e) => InvoiceReceiptReturn.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      summary: InvoiceReceiptSummary.fromJson(summaryJson),
    );
  }
}

class InvoiceReceiptHeader {
  const InvoiceReceiptHeader({
    this.invoiceNumber,
    this.total,
    this.returnStatus,
    this.customerName,
    this.branchName,
    this.createdAt,
  });

  final String? invoiceNumber;
  final double? total;
  final String? returnStatus;
  final String? customerName;
  final String? branchName;
  final String? createdAt;

  factory InvoiceReceiptHeader.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;
    return InvoiceReceiptHeader(
      invoiceNumber: json['invoice_number'] as String?,
      total: (json['total'] as num?)?.toDouble(),
      returnStatus: json['return_status'] as String?,
      customerName: customer?['name'] as String?,
      branchName: branch?['name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class InvoiceReceiptLine {
  const InvoiceReceiptLine({
    required this.partId,
    required this.quantity,
    this.unitPrice,
    this.lineTotal,
    this.quantityReturnedCompleted = 0,
    this.quantityReturnedPending = 0,
    this.quantityRemaining = 0,
    this.partCode,
    this.partName,
  });

  final String partId;
  final double quantity;
  final double? unitPrice;
  final double? lineTotal;
  final double quantityReturnedCompleted;
  final double quantityReturnedPending;
  final double quantityRemaining;
  final String? partCode;
  final String? partName;

  factory InvoiceReceiptLine.fromJson(Map<String, dynamic> json) {
    final part = json['part'] as Map<String, dynamic>?;
    return InvoiceReceiptLine(
      partId: json['part_id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      quantityReturnedCompleted:
          (json['quantity_returned_completed'] as num?)?.toDouble() ?? 0,
      quantityReturnedPending:
          (json['quantity_returned_pending'] as num?)?.toDouble() ?? 0,
      quantityRemaining: (json['quantity_remaining'] as num?)?.toDouble() ?? 0,
      partCode: part?['code'] as String? ?? json['part_code'] as String?,
      partName: part?['name'] as String? ?? json['part_name'] as String?,
    );
  }
}

class InvoiceReceiptReturn {
  const InvoiceReceiptReturn({
    this.returnNumber,
    this.status,
    this.resolution,
    this.totalValue,
    this.items = const [],
  });

  final String? returnNumber;
  final String? status;
  final String? resolution;
  final double? totalValue;
  final List<InvoiceReceiptReturnItem> items;

  factory InvoiceReceiptReturn.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return InvoiceReceiptReturn(
      returnNumber: json['return_number'] as String?,
      status: json['status'] as String?,
      resolution: json['resolution'] as String?,
      totalValue: (json['total_value'] as num?)?.toDouble(),
      items: itemsJson
          .whereType<Map>()
          .map(
            (e) => InvoiceReceiptReturnItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class InvoiceReceiptReturnItem {
  const InvoiceReceiptReturnItem({
    this.partCode,
    this.quantity,
    this.unitPrice,
  });

  final String? partCode;
  final double? quantity;
  final double? unitPrice;

  factory InvoiceReceiptReturnItem.fromJson(Map<String, dynamic> json) =>
      InvoiceReceiptReturnItem(
        partCode: json['part_code'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unitPrice: (json['unit_price'] as num?)?.toDouble(),
      );
}

class InvoiceReceiptSummary {
  const InvoiceReceiptSummary({
    this.originalSubtotal,
    this.originalDiscount,
    this.originalTotal,
    this.returnedValueCompleted,
    this.returnedValuePending,
    this.netTotalAfterCompletedReturns,
  });

  final double? originalSubtotal;
  final double? originalDiscount;
  final double? originalTotal;
  final double? returnedValueCompleted;
  final double? returnedValuePending;
  final double? netTotalAfterCompletedReturns;

  factory InvoiceReceiptSummary.fromJson(Map<String, dynamic> json) =>
      InvoiceReceiptSummary(
        originalSubtotal: (json['original_subtotal'] as num?)?.toDouble(),
        originalDiscount: (json['original_discount'] as num?)?.toDouble(),
        originalTotal: (json['original_total'] as num?)?.toDouble(),
        returnedValueCompleted:
            (json['returned_value_completed'] as num?)?.toDouble(),
        returnedValuePending:
            (json['returned_value_pending'] as num?)?.toDouble(),
        netTotalAfterCompletedReturns:
            (json['net_total_after_completed_returns'] as num?)?.toDouble(),
      );
}
