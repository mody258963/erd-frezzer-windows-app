enum UserRole {
  admin,
  manager,
  salesperson,
  warehouse;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.salesperson,
    );
  }
}
