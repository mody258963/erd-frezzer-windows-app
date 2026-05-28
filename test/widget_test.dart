import 'package:erd_rezzer/core/auth/role_permissions.dart';
import 'package:erd_rezzer/data/models/user_role.dart';
import 'package:erd_rezzer/router/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('warehouse cannot access POS route', () {
    expect(
      RolePermissions.canAccessRoute(RoutePaths.pos, UserRole.warehouse),
      false,
    );
  });

  test('offline allows POS and sync', () {
    expect(RolePermissions.isOfflineAllowed(RoutePaths.pos), true);
    expect(RolePermissions.isOfflineAllowed(RoutePaths.sync), true);
    expect(RolePermissions.isOfflineAllowed(RoutePaths.dashboard), false);
  });

  test('salesperson can create invoices', () {
    expect(
      RolePermissions.canPerform(AppAction.invoiceCreate, UserRole.salesperson),
      true,
    );
  });
}
