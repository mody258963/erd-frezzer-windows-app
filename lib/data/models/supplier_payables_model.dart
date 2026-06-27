import '../../core/api/api_utils.dart';
import 'supplier_installment_model.dart';
import 'supplier_model.dart';

class SupplierPayableGroup {
  const SupplierPayableGroup({
    required this.supplier,
    this.purchaseOrders = const [],
    this.installments = const [],
  });

  final SupplierModel supplier;
  final List<Map<String, dynamic>> purchaseOrders;
  final List<SupplierInstallmentModel> installments;

  double get totalDebt => supplier.outstandingBalance;

  factory SupplierPayableGroup.fromJson(Map<String, dynamic> json) {
    final supplierJson = json['supplier'] as Map<String, dynamic>? ?? json;
    return SupplierPayableGroup(
      supplier: SupplierModel.fromJson(Map<String, dynamic>.from(supplierJson)),
      purchaseOrders: (json['purchase_orders'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      installments: parseList(
        json['installments'],
        SupplierInstallmentModel.fromJson,
      ),
    );
  }
}

class SupplierPayablesResponse {
  const SupplierPayablesResponse({
    required this.suppliers,
    required this.totalSupplierDebt,
  });

  final List<SupplierPayableGroup> suppliers;
  final double totalSupplierDebt;

  factory SupplierPayablesResponse.fromJson(Map<String, dynamic> json) {
    final rows = (json['suppliers'] as List<dynamic>?)
            ?.map(
              (e) => SupplierPayableGroup.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        const <SupplierPayableGroup>[];
    final apiTotal = (json['total_supplier_debt'] as num?)?.toDouble();
    final total = apiTotal ??
        rows.fold<double>(0.0, (sum, g) => sum + g.totalDebt);
    return SupplierPayablesResponse(
      suppliers: rows,
      totalSupplierDebt: total,
    );
  }

  /// Shape expected by dashboard finance hub creditors list.
  Map<String, dynamic> toPayablesMap() {
    return {
      'suppliers': suppliers
          .map(
            (g) => {
              'name': g.supplier.name,
              'supplier_name': g.supplier.name,
              'outstanding_balance': g.totalDebt,
              'balance': g.totalDebt,
              'debt': g.totalDebt,
              'supplier': {
                'id': g.supplier.id,
                'name': g.supplier.name,
                'total_debt': g.totalDebt,
              },
            },
          )
          .toList(),
      'total_supplier_debt': totalSupplierDebt,
    };
  }
}
