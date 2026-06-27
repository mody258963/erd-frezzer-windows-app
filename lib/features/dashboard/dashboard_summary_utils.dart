double summaryNum(Map<String, dynamic> summary, String key) {
  final v = summary[key];
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

/// Reads `period_*` from summary; falls back to legacy `weekly_*` only when absent.
double summaryPeriodNum(Map<String, dynamic> summary, String suffix) {
  final periodKey = 'period_$suffix';
  if (summary.containsKey(periodKey)) {
    return summaryNum(summary, periodKey);
  }
  final weeklyKey = 'weekly_$suffix';
  if (summary.containsKey(weeklyKey)) {
    return summaryNum(summary, weeklyKey);
  }
  return 0;
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

/// `period_net_cash_flow_realized ≈ period_cash_in − period_cash_out` (±0.02).
bool summaryNetCashFlowConsistent(Map<String, dynamic> summary) {
  final cashIn = summaryPeriodNum(summary, 'cash_in_realized');
  final cashOut = summaryPeriodNum(summary, 'cash_out_realized');
  final net = summaryPeriodNum(summary, 'net_cash_flow_realized');
  return (net - (cashIn - cashOut)).abs() < 0.02;
}

/// `period_profit ≈ gross − discount − refund impact` (±0.02).
bool summaryProfitConsistent(Map<String, dynamic> summary) {
  final profit = summaryPeriodNum(summary, 'profit');
  final gross = summaryPeriodNum(summary, 'gross_profit');
  final discount = summaryPeriodNum(summary, 'discount');
  final impact = summaryPeriodNum(summary, 'customer_refund_profit_impact');
  return (profit - (gross - discount - impact)).abs() < 0.02;
}
