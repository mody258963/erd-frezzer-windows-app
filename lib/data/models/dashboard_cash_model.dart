/// Realized cash from `GET /dashboard/cash` and/or `GET /dashboard/summary`.
class DashboardCash {
  const DashboardCash({
    this.cashOnHandRealized = 0,
    this.mustCollectCustomers = 0,
    this.mustPaySuppliers = 0,
    this.periodCashInRealized = 0,
    this.periodCashOutRealized = 0,
    this.periodNetCashFlowRealized = 0,
    this.lifetimeCashInRealized = 0,
    this.lifetimeCashOutRealized = 0,
    this.legacyEstimatedAvailable,
  });

  /// Lifetime snapshot — unchanged across period tabs.
  final double cashOnHandRealized;
  final double mustCollectCustomers;
  final double mustPaySuppliers;

  /// Selected period window only.
  final double periodCashInRealized;
  final double periodCashOutRealized;
  final double periodNetCashFlowRealized;

  final double lifetimeCashInRealized;
  final double lifetimeCashOutRealized;
  final double? legacyEstimatedAvailable;

  bool get hasPeriodCashFlow =>
      periodCashInRealized != 0 ||
      periodCashOutRealized != 0 ||
      periodNetCashFlowRealized != 0;

  bool get hasData =>
      cashOnHandRealized != 0 ||
      mustCollectCustomers != 0 ||
      mustPaySuppliers != 0 ||
      hasPeriodCashFlow ||
      lifetimeCashInRealized != 0 ||
      lifetimeCashOutRealized != 0 ||
      legacyEstimatedAvailable != null;

  /// `period_net_cash_flow_realized ≈ period_cash_in − period_cash_out` (±0.02).
  bool get cashFlowConsistent {
    final expected = periodCashInRealized - periodCashOutRealized;
    return (periodNetCashFlowRealized - expected).abs() < 0.02;
  }

  /// Snapshot fields prefer `/dashboard/cash` when present; period flow from cash endpoint.
  factory DashboardCash.fromResponses({
    required Map<String, dynamic> summary,
    Map<String, dynamic>? cashEndpoint,
  }) {
    final periodSource = cashEndpoint ?? summary;

    return DashboardCash(
      cashOnHandRealized: _snapshotNum(
        cashEndpoint,
        summary,
        'cash_on_hand_realized',
      ),
      mustCollectCustomers: _snapshotNum(
        cashEndpoint,
        summary,
        'must_collect_customers',
        legacyKey: 'total_receivables',
      ),
      mustPaySuppliers: _snapshotNum(
        cashEndpoint,
        summary,
        'must_pay_suppliers',
        legacyKey: 'total_supplier_debt',
      ),
      periodCashInRealized: _periodNum(periodSource, 'cash_in_realized'),
      periodCashOutRealized: _periodNum(periodSource, 'cash_out_realized'),
      periodNetCashFlowRealized:
          _periodNum(periodSource, 'net_cash_flow_realized'),
      lifetimeCashInRealized: _snapshotNum(
        cashEndpoint,
        summary,
        'lifetime_cash_in_realized',
      ),
      lifetimeCashOutRealized: _snapshotNum(
        cashEndpoint,
        summary,
        'lifetime_cash_out_realized',
      ),
      legacyEstimatedAvailable: _optionalNum(summary['legacy_estimated_available']),
    );
  }

  static double _snapshotNum(
    Map<String, dynamic>? cashEndpoint,
    Map<String, dynamic> summary,
    String key, {
    String? legacyKey,
  }) {
    if (cashEndpoint != null && cashEndpoint.containsKey(key)) {
      return _num(cashEndpoint[key]);
    }
    if (summary.containsKey(key)) return _num(summary[key]);
    if (legacyKey != null && summary.containsKey(legacyKey)) {
      return _num(summary[legacyKey]);
    }
    return 0;
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  static double? _optionalNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static double _periodNum(Map<String, dynamic> json, String suffix) {
    final periodKey = 'period_$suffix';
    if (json.containsKey(periodKey)) return _num(json[periodKey]);
    final weeklyKey = 'weekly_$suffix';
    if (json.containsKey(weeklyKey)) return _num(json[weeklyKey]);
    return 0;
  }
}
