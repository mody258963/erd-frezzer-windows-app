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
  });

  final double inventoryAtCost;
  final double customerReceivables;
  final double supplierDebt;
  final double deployedCapital;
  final double estimatedAvailable;

  factory FinancingSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FinancingSnapshot();
    return FinancingSnapshot(
      inventoryAtCost: _num(json['inventory_at_cost']),
      customerReceivables: _num(json['customer_receivables']),
      supplierDebt: _num(json['supplier_debt']),
      deployedCapital: _num(json['deployed_capital']),
      estimatedAvailable: _num(json['estimated_available']),
    );
  }
}

class CapitalSettings {
  const CapitalSettings({
    this.capitalAmount = 0,
    this.currency = 'EGP',
    this.financingSnapshot,
    this.profitWithdrawal,
    this.updatedAt,
  });

  final double capitalAmount;
  final String currency;
  final FinancingSnapshot? financingSnapshot;
  final ProfitWithdrawal? profitWithdrawal;
  final String? updatedAt;

  factory CapitalSettings.fromJson(Map<String, dynamic> json) {
    final snap = json['financing_snapshot'];
    final profit = json['profit_withdrawal'];
    return CapitalSettings(
      capitalAmount: _num(
        json['capital_amount'] ?? json['business_capital'],
      ),
      currency: '${json['capital_currency'] ?? json['currency'] ?? 'EGP'}',
      financingSnapshot: snap is Map<String, dynamic>
          ? FinancingSnapshot.fromJson(snap)
          : null,
      profitWithdrawal: profit is Map<String, dynamic>
          ? ProfitWithdrawal.fromJson(profit)
          : _profitFromSummaryFields(json),
      updatedAt: json['updated_at'] as String?,
    );
  }

  static ProfitWithdrawal? _profitFromSummaryFields(Map<String, dynamic> json) {
    if (json['withdrawable_profit'] == null &&
        json['realized_profit'] == null &&
        json['total_owner_cash_outs'] == null) {
      return null;
    }
    return ProfitWithdrawal(
      realizedProfit: _num(json['realized_profit']),
      totalWithdrawn: _num(json['total_owner_cash_outs']),
      withdrawableProfit: _num(json['withdrawable_profit']),
      branchId: json['branch_id'] as String?,
    );
  }
}

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
