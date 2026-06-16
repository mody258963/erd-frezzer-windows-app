import 'return_resolutions.dart';

class ReturnLineInfo {
  const ReturnLineInfo({
    required this.partId,
    required this.quantity,
    required this.unitPrice,
    required this.condition,
    this.partLabel,
  });

  final String partId;
  final int quantity;
  final double unitPrice;
  final String condition;
  final String? partLabel;

  double get lineTotal => unitPrice * quantity;

  bool get isDefective => condition.toLowerCase() == 'defective';
}

/// Parses return line items from list/detail API JSON.
List<ReturnLineInfo> parseReturnItems(Map<String, dynamic> row) {
  final raw = row['items'] as List<dynamic>? ?? [];
  return [
    for (final e in raw)
      if (e is Map<String, dynamic>) _lineFromJson(e),
  ];
}

ReturnLineInfo _lineFromJson(Map<String, dynamic> json) {
  final part = json['part'] as Map<String, dynamic>?;
  final code = part?['code'] as String?;
  final name = part?['name'] as String?;
  final label = code != null && name != null
      ? '$code — $name'
      : (name ?? code ?? json['part_id'] as String? ?? '');
  return ReturnLineInfo(
    partId: json['part_id'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    condition: json['condition'] as String? ?? 'sellable',
    partLabel: label.isEmpty ? null : label,
  );
}

bool isCustomerReturn(Map<String, dynamic> row) {
  final t = (row['return_type'] as String? ?? '').toLowerCase();
  return t.isEmpty || t == ReturnResolutions.customerReturn;
}

/// Suggested resolution per API rules (customer returns).
String suggestCustomerResolution(
  Map<String, dynamic> row,
  List<ReturnLineInfo> items,
) {
  if (!isCustomerReturn(row)) {
    return ReturnResolutions.defaultFor(row['return_type'] as String?);
  }

  final hasDefective = items.any((i) => i.isDefective);
  if (hasDefective) {
    return 'writeoff';
  }

  final payment = _paymentType(row).toLowerCase();
  if (payment == 'credit') return 'credit_note';
  if (payment == 'cash' || payment == 'immediate') return 'refund_cash';

  return 'restock';
}

String _paymentType(Map<String, dynamic> row) {
  final inv = row['invoice'] as Map<String, dynamic>?;
  return row['payment_type'] as String? ??
      inv?['payment_type'] as String? ??
      '';
}

/// Resolutions allowed in the approve dropdown for this return.
List<String> resolutionsForApprove(
  Map<String, dynamic> row,
  List<ReturnLineInfo> items,
) {
  final type = row['return_type'] as String?;
  if (!isCustomerReturn(row)) {
    return ReturnResolutions.choicesFor(type);
  }

  final hasDefective = items.any((i) => i.isDefective);
  final allDefective = items.isNotEmpty && items.every((i) => i.isDefective);

  if (allDefective) {
    return const ['writeoff', 'refund_cash'];
  }
  if (hasDefective) {
    return ReturnResolutions.customerChoices;
  }
  return ReturnResolutions.customerChoices;
}

bool resolutionRestocksStock(String resolution) {
  const restock = {'restock', 'refund_cash', 'credit_note', 'replace'};
  return restock.contains(resolution);
}

bool resolutionRefundsCustomer(String resolution) {
  const refund = {'refund_cash', 'writeoff', 'credit_note'};
  return refund.contains(resolution);
}

double returnTotalValue(List<ReturnLineInfo> items) =>
    items.fold(0.0, (s, i) => s + i.lineTotal);

/// Invoice UUID for `reference_id` when reference_type is invoice.
String? invoiceIdFromReturnRow(Map<String, dynamic> row) {
  final refType = (row['reference_type'] as String? ?? '').toLowerCase();
  if (refType == 'invoice') {
    final id = row['reference_id'] as String?;
    if (id != null && id.isNotEmpty) return id;
  }
  final invoice = row['invoice'];
  if (invoice is Map<String, dynamic>) {
    return invoice['id'] as String?;
  }
  return row['invoice_id'] as String?;
}

/// Body for `POST /returns` — [referenceId] must be invoice.id, not customer id.
Map<String, dynamic> buildCustomerReturnBody({
  required String referenceId,
  required String customerId,
  required String branchId,
  required String reason,
  required List<Map<String, dynamic>> items,
}) {
  return {
    'return_type': 'customer_return',
    'reference_type': 'invoice',
    'reference_id': referenceId,
    'customer_id': customerId,
    'branch_id': branchId,
    'reason': reason,
    'items': items,
  };
}
