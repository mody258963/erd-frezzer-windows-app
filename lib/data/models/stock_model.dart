import 'part_model.dart';

class StockModel {
  const StockModel({
    required this.partId,
    required this.branchId,
    required this.quantity,
    this.averageCost,
    this.valueAtCost,
    this.part,
    this.branchName,
  });

  final String partId;
  final String branchId;
  final double quantity;
  final double? averageCost;
  final double? valueAtCost;
  final PartModel? part;
  final String? branchName;

  factory StockModel.fromJson(Map<String, dynamic> json) {
    final partJson = json['part'] as Map<String, dynamic>?;
    final branchJson = json['branch'] as Map<String, dynamic>?;
    return StockModel(
      partId: json['part_id'] as String,
      branchId: json['branch_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      averageCost: (json['average_cost'] as num?)?.toDouble(),
      valueAtCost: (json['value_at_cost'] as num?)?.toDouble(),
      part: partJson != null ? PartModel.fromJson(partJson) : null,
      branchName: branchJson?['name'] as String?,
    );
  }
}
