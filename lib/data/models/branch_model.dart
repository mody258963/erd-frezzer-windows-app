class BranchModel {
  const BranchModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        'is_active': isActive,
      };
}
