double summaryNum(Map<String, dynamic> summary, String key) {
  final v = summary[key];
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

int summaryInt(Map<String, dynamic> summary, String key) {
  final v = summary[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

/// Overdue installment count from new or legacy summary keys.
int summaryOverdueInstallmentCount(Map<String, dynamic> summary) {
  if (summary.containsKey('overdue_installments_count')) {
    return summaryInt(summary, 'overdue_installments_count');
  }
  return summaryInt(summary, 'overdue_installments');
}

List<Map<String, dynamic>> payablesInstallmentList(
  Map<String, dynamic>? payables,
  String kind,
) {
  if (payables == null) return [];
  final keys = kind == 'overdue'
      ? ['overdue_installments', 'overdue', 'overdue_installment']
      : ['upcoming_installments', 'upcoming', 'due_soon_installments'];
  for (final key in keys) {
    final v = payables[key];
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  return [];
}
