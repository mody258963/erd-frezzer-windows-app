class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.address,
    this.email,
    this.outstandingBalance = 0,
    this.isActive = true,
    this.notes,
    this.linkedCustomerId,
    this.branchId,
  });

  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? address;
  final String? email;
  final double outstandingBalance;
  final bool isActive;
  final String? notes;
  final String? linkedCustomerId;
  final String? branchId;

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
        id: json['id'] as String,
        name: json['name'] as String,
        contactPerson: json['contact_person'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        email: json['email'] as String?,
        outstandingBalance:
            (json['total_debt'] as num?)?.toDouble() ??
            (json['outstanding_balance'] as num?)?.toDouble() ??
            0,
        isActive: json['is_active'] as bool? ?? true,
        notes: json['notes'] as String?,
        linkedCustomerId: json['linked_customer_id'] as String?,
        branchId: json['branch_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (contactPerson != null && contactPerson!.isNotEmpty)
          'contact_person': contactPerson,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'is_active': isActive,
      };
}
