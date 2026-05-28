class PartModel {
  const PartModel({
    required this.id,
    required this.code,
    required this.name,
    this.categoryKey,
    this.categoryName,
    this.categoryId,
    this.unit,
    this.unitLabel,
    required this.sellPrice,
    this.costPrice = 0,
    this.minStock = 0,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String name;
  final String? categoryKey;
  final String? categoryName;
  final String? categoryId;
  final String? unit;
  final String? unitLabel;
  final double sellPrice;
  final double costPrice;
  final int minStock;
  final String? imageUrl;
  final bool isActive;

  /// Display label for lists (category name).
  String get categoryDisplay => categoryName ?? categoryKey ?? '—';

  factory PartModel.fromJson(Map<String, dynamic> json) {
    final nested = json['category'];
    String? name = json['category_name'] as String?;
    String? key = json['category_key'] as String?;
    if (nested is Map) {
      name ??= nested['name'] as String?;
      key ??= nested['key'] as String?;
    } else if (nested is String) {
      name ??= nested;
    }

    return PartModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      categoryKey: key,
      categoryName: name,
      categoryId: json['category_id'] as String?,
      unit: json['unit'] as String?,
      unitLabel: json['unit_label'] as String?,
      sellPrice: (json['sell_price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
      minStock: (json['min_stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        if (categoryKey != null && categoryKey!.isNotEmpty)
          'category_key': categoryKey,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        'sell_price': sellPrice,
        'cost_price': costPrice,
        'min_stock': minStock,
        'is_active': isActive,
      };
}
