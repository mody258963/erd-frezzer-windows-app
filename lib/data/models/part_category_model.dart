class PartCategoryModel {
  const PartCategoryModel({
    required this.id,
    required this.key,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String key;
  final String name;
  final int sortOrder;
  final bool isActive;

  factory PartCategoryModel.fromJson(Map<String, dynamic> json) =>
      PartCategoryModel(
        id: '${json['id']}',
        key: '${json['key']}',
        name: '${json['name']}',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class PartUnitOption {
  const PartUnitOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  factory PartUnitOption.fromJson(Map<String, dynamic> json) => PartUnitOption(
        value: '${json['value']}',
        label: '${json['label']}',
      );
}
