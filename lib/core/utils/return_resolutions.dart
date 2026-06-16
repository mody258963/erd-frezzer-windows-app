/// Approve resolutions for `PATCH /returns/{id}/approve`.
class ReturnResolutions {
  static const customerReturn = 'customer_return';
  static const supplierReturn = 'supplier_return';

  static const customerChoices = [
    'restock',
    'credit_note',
    'refund_cash',
    'replace',
    'writeoff',
  ];

  static const supplierChoices = [
    'supplier_credit',
    'writeoff',
  ];

  static List<String> choicesFor(String? returnType) {
    final t = (returnType ?? '').toLowerCase();
    if (t == supplierReturn) return supplierChoices;
    return customerChoices;
  }

  static String defaultFor(String? returnType) {
    final t = (returnType ?? '').toLowerCase();
    if (t == supplierReturn) return 'supplier_credit';
    return 'restock';
  }
}
