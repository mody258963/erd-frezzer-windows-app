const _balanceKeys = [
  'outstanding_balance',
  'total_debt',
  'balance',
  'debt',
  'amount',
];

/// Reads outstanding balance from API debt/balance payloads.
double parseOutstandingBalance(Map<String, dynamic> data) {
  final direct = _balanceFromMap(data);
  if (direct != null) return direct;

  for (final key in ['supplier', 'customer']) {
    final nested = data[key];
    if (nested is Map) {
      final fromNested = _balanceFromMap(Map<String, dynamic>.from(nested));
      if (fromNested != null) return fromNested;
    }
  }
  return 0;
}

double? _balanceFromMap(Map<String, dynamic> data) {
  for (final key in _balanceKeys) {
    final v = data[key];
    if (v is num) return v.toDouble();
  }
  return null;
}