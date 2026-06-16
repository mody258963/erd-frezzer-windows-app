class PartAnalysisData {
  const PartAnalysisData({
    required this.part,
    required this.period,
    required this.inventory,
    required this.sales,
    required this.purchases,
    required this.returns,
    required this.movements,
    required this.salesByMonth,
  });

  final Map<String, dynamic> part;
  final PartAnalysisPeriod period;
  final PartAnalysisInventory inventory;
  final PartAnalysisSales sales;
  final PartAnalysisPurchases purchases;
  final PartAnalysisReturns returns;
  final PartAnalysisMovements movements;
  final List<PartAnalysisMonthSales> salesByMonth;

  factory PartAnalysisData.fromJson(Map<String, dynamic> json) =>
      PartAnalysisData(
        part: Map<String, dynamic>.from(json['part'] as Map? ?? {}),
        period: PartAnalysisPeriod.fromJson(
          Map<String, dynamic>.from(json['period'] as Map? ?? {}),
        ),
        inventory: PartAnalysisInventory.fromJson(
          Map<String, dynamic>.from(json['inventory'] as Map? ?? {}),
        ),
        sales: PartAnalysisSales.fromJson(
          Map<String, dynamic>.from(json['sales'] as Map? ?? {}),
        ),
        purchases: PartAnalysisPurchases.fromJson(
          Map<String, dynamic>.from(json['purchases'] as Map? ?? {}),
        ),
        returns: PartAnalysisReturns.fromJson(
          Map<String, dynamic>.from(json['returns'] as Map? ?? {}),
        ),
        movements: PartAnalysisMovements.fromJson(
          Map<String, dynamic>.from(json['movements'] as Map? ?? {}),
        ),
        salesByMonth: (json['sales_by_month'] as List? ?? [])
            .map(
              (e) => PartAnalysisMonthSales.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );

  String get partTitle {
    final code = '${part['code'] ?? ''}';
    final name = '${part['name'] ?? ''}';
    if (code.isNotEmpty && name.isNotEmpty) return '$code — $name';
    return name.isNotEmpty ? name : code;
  }
}

class PartAnalysisPeriod {
  const PartAnalysisPeriod({this.from, this.to, this.branchId});

  final String? from;
  final String? to;
  final String? branchId;

  factory PartAnalysisPeriod.fromJson(Map<String, dynamic> json) =>
      PartAnalysisPeriod(
        from: json['from'] as String?,
        to: json['to'] as String?,
        branchId: json['branch_id'] as String?,
      );
}

class PartAnalysisInventory {
  const PartAnalysisInventory({
    required this.totalQuantity,
    required this.minStock,
    required this.isBelowMinStock,
    required this.averageCost,
    required this.valueAtCost,
    required this.valueAtSell,
    required this.marginPerUnit,
    required this.byBranch,
  });

  final int totalQuantity;
  final int minStock;
  final bool isBelowMinStock;
  final double averageCost;
  final double valueAtCost;
  final double valueAtSell;
  final double marginPerUnit;
  final List<PartAnalysisBranchQty> byBranch;

  factory PartAnalysisInventory.fromJson(Map<String, dynamic> json) =>
      PartAnalysisInventory(
        totalQuantity: _int(json['total_quantity']),
        minStock: _int(json['min_stock']),
        isBelowMinStock: json['is_below_min_stock'] as bool? ?? false,
        averageCost: _double(json['average_cost']),
        valueAtCost: _double(json['value_at_cost']),
        valueAtSell: _double(json['value_at_sell']),
        marginPerUnit: _double(json['margin_per_unit']),
        byBranch: (json['by_branch'] as List? ?? [])
            .map(
              (e) => PartAnalysisBranchQty.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}

class PartAnalysisBranchQty {
  const PartAnalysisBranchQty({
    required this.branchId,
    required this.branchName,
    required this.quantity,
    this.averageCost,
  });

  final String branchId;
  final String branchName;
  final int quantity;
  final double? averageCost;

  factory PartAnalysisBranchQty.fromJson(Map<String, dynamic> json) =>
      PartAnalysisBranchQty(
        branchId: '${json['branch_id'] ?? ''}',
        branchName: '${json['branch_name'] ?? '—'}',
        quantity: _int(json['quantity']),
        averageCost: (json['average_cost'] as num?)?.toDouble(),
      );
}

class PartAnalysisSales {
  const PartAnalysisSales({
    required this.unitsSold,
    required this.revenue,
    required this.invoiceCount,
    required this.estimatedCogs,
    required this.grossProfit,
    required this.grossMarginPercent,
  });

  final int unitsSold;
  final double revenue;
  final int invoiceCount;
  final double estimatedCogs;
  final double grossProfit;
  final double grossMarginPercent;

  factory PartAnalysisSales.fromJson(Map<String, dynamic> json) =>
      PartAnalysisSales(
        unitsSold: _int(json['units_sold']),
        revenue: _double(json['revenue']),
        invoiceCount: _int(json['invoice_count']),
        estimatedCogs: _double(json['estimated_cogs']),
        grossProfit: _double(json['gross_profit']),
        grossMarginPercent: _double(json['gross_margin_percent']),
      );
}

class PartAnalysisPurchases {
  const PartAnalysisPurchases({
    required this.unitsPurchased,
    required this.cost,
    required this.orderCount,
  });

  final int unitsPurchased;
  final double cost;
  final int orderCount;

  factory PartAnalysisPurchases.fromJson(Map<String, dynamic> json) =>
      PartAnalysisPurchases(
        unitsPurchased: _int(json['units_purchased']),
        cost: _double(json['cost']),
        orderCount: _int(json['order_count']),
      );
}

class PartAnalysisReturns {
  const PartAnalysisReturns({
    required this.unitsReturned,
    required this.value,
    required this.returnCount,
  });

  final int unitsReturned;
  final double value;
  final int returnCount;

  factory PartAnalysisReturns.fromJson(Map<String, dynamic> json) =>
      PartAnalysisReturns(
        unitsReturned: _int(json['units_returned']),
        value: _double(json['value']),
        returnCount: _int(json['return_count']),
      );
}

class PartAnalysisMovements {
  const PartAnalysisMovements({
    required this.byType,
    required this.recent,
  });

  final List<PartAnalysisMovementType> byType;
  final List<PartAnalysisMovement> recent;

  factory PartAnalysisMovements.fromJson(Map<String, dynamic> json) =>
      PartAnalysisMovements(
        byType: (json['by_type'] as List? ?? [])
            .map(
              (e) => PartAnalysisMovementType.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
        recent: (json['recent'] as List? ?? [])
            .map(
              (e) => PartAnalysisMovement.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}

class PartAnalysisMovementType {
  const PartAnalysisMovementType({
    required this.movementType,
    required this.quantity,
  });

  final String movementType;
  final int quantity;

  factory PartAnalysisMovementType.fromJson(Map<String, dynamic> json) =>
      PartAnalysisMovementType(
        movementType: '${json['movement_type'] ?? ''}',
        quantity: _int(json['quantity']),
      );
}

class PartAnalysisMovement {
  const PartAnalysisMovement({
    required this.id,
    required this.movementType,
    required this.quantity,
    required this.branchName,
    required this.referenceType,
    required this.createdByName,
    required this.createdAt,
  });

  final String id;
  final String movementType;
  final int quantity;
  final String branchName;
  final String? referenceType;
  final String? createdByName;
  final String? createdAt;

  factory PartAnalysisMovement.fromJson(Map<String, dynamic> json) =>
      PartAnalysisMovement(
        id: '${json['id'] ?? ''}',
        movementType: '${json['movement_type'] ?? ''}',
        quantity: _int(json['quantity']),
        branchName: '${json['branch_name'] ?? '—'}',
        referenceType: json['reference_type'] as String?,
        createdByName: json['created_by_name'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

class PartAnalysisMonthSales {
  const PartAnalysisMonthSales({
    required this.month,
    required this.unitsSold,
    required this.revenue,
  });

  final String month;
  final int unitsSold;
  final double revenue;

  factory PartAnalysisMonthSales.fromJson(Map<String, dynamic> json) =>
      PartAnalysisMonthSales(
        month: '${json['month'] ?? ''}',
        unitsSold: _int(json['units_sold']),
        revenue: _double(json['revenue']),
      );
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
