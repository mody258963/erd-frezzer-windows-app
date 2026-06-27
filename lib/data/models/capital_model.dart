class ProfitWithdrawal {
  const ProfitWithdrawal({
    this.realizedProfit = 0,
    this.totalWithdrawn = 0,
    this.withdrawableProfit = 0,
    this.branchId,
  });

  final double realizedProfit;
  final double totalWithdrawn;
  final double withdrawableProfit;
  final String? branchId;

  factory ProfitWithdrawal.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProfitWithdrawal();
    return ProfitWithdrawal(
      realizedProfit: _num(json['realized_profit']),
      totalWithdrawn: _num(json['total_withdrawn'] ?? json['total_owner_cash_outs']),
      withdrawableProfit: _num(json['withdrawable_profit']),
      branchId: json['branch_id'] as String?,
    );
  }
}

class FinancingSnapshot {
  const FinancingSnapshot({
    this.inventoryAtCost = 0,
    this.customerReceivables = 0,
    this.supplierDebt = 0,
    this.deployedCapital = 0,
    this.estimatedAvailable = 0,
    this.cashOnHandRealized = 0,
    this.businessCapital = 0,
  });

  final double inventoryAtCost;
  final double customerReceivables;
  final double supplierDebt;
  final double deployedCapital;
  final double estimatedAvailable;
  final double cashOnHandRealized;
  final double businessCapital;

  factory FinancingSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FinancingSnapshot();
    final inventory = _num(json['inventory_at_cost']);
    final cash = _num(json['cash_on_hand_realized']);
    final business = _num(json['business_capital']);
    return FinancingSnapshot(
      inventoryAtCost: inventory,
      customerReceivables: _num(json['customer_receivables']),
      supplierDebt: _num(json['supplier_debt']),
      deployedCapital: _num(json['deployed_capital']),
      estimatedAvailable: _num(json['estimated_available']),
      cashOnHandRealized: cash,
      businessCapital: business > 0 ? business : inventory + cash,
    );
  }
}

class CapitalSettings {
  const CapitalSettings({
    this.openingCashBalance = 0,
    this.businessCapital = 0,
    this.currency = 'EGP',
    this.financingSnapshot,
    this.profitWithdrawal,
    this.updatedAt,
  });

  /// Admin-set opening cash (`opening_cash_balance` / `capital_amount` in API).
  final double openingCashBalance;

  /// Computed: inventory at cost + realized cash on hand.
  final double businessCapital;
  final String currency;
  final FinancingSnapshot? financingSnapshot;
  final ProfitWithdrawal? profitWithdrawal;
  final String? updatedAt;

  /// Alias kept for repository `capital_amount` body field.
  double get capitalAmount => openingCashBalance;

  double get inventoryAtCost =>
      financingSnapshot?.inventoryAtCost ?? 0;

  double get cashOnHandRealized =>
      financingSnapshot?.cashOnHandRealized ?? 0;

  double get withdrawableProfit => profitWithdrawal?.withdrawableProfit ?? 0;

  double get realizedProfit => profitWithdrawal?.realizedProfit ?? 0;

  double get totalProfitWithdrawn => profitWithdrawal?.totalWithdrawn ?? 0;

  factory CapitalSettings.fromJson(Map<String, dynamic> json) {
    final snapRaw = json['financing_snapshot'];
    final snap = snapRaw is Map<String, dynamic>
        ? FinancingSnapshot.fromJson(snapRaw)
        : null;
    final profit = json['profit_withdrawal'];
    final opening = _num(json['opening_cash_balance'] ?? json['capital_amount']);
    var business = _num(json['business_capital']);
    if (business <= 0 && snap != null) {
      business = snap.businessCapital;
    }
    if (business <= 0) {
      business = _num(json['total_stock_value_cost']) +
          _num(json['cash_on_hand_realized']);
    }
    return CapitalSettings(
      openingCashBalance: opening,
      businessCapital: business,
      currency: '${json['capital_currency'] ?? json['currency'] ?? 'EGP'}',
      financingSnapshot: snap,
      profitWithdrawal: profit is Map<String, dynamic>
          ? ProfitWithdrawal.fromJson(profit)
          : _profitFromSummaryFields(json),
      updatedAt: json['updated_at'] as String?,
    );
  }

  static ProfitWithdrawal? _profitFromSummaryFields(Map<String, dynamic> json) {
    if (json['withdrawable_profit'] == null &&
        json['realized_profit'] == null &&
        json['total_owner_cash_outs'] == null &&
        json['total_withdrawn'] == null) {
      return null;
    }
    return ProfitWithdrawal(
      realizedProfit: _num(json['realized_profit']),
      totalWithdrawn: _num(json['total_withdrawn'] ?? json['total_owner_cash_outs']),
      withdrawableProfit: _num(json['withdrawable_profit']),
      branchId: json['branch_id'] as String?,
    );
  }
}

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
