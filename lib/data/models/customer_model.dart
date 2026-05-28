class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.address,
    this.creditLimit = 0,
    this.outstandingBalance = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String type;
  final String? phone;
  final String? address;
  final double creditLimit;
  final double outstandingBalance;
  final bool isActive;

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
        outstandingBalance:
            (json['outstanding_balance'] as num?)?.toDouble() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (type == 'credit') 'credit_limit': creditLimit,
        'is_active': isActive,
      };
}
