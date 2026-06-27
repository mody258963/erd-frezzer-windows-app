import 'package:erd_rezzer/core/auth/role_permissions.dart';
import 'package:erd_rezzer/core/l10n/report_labels.dart';
import 'package:erd_rezzer/data/models/user_role.dart';
import 'package:erd_rezzer/router/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('route access', () {
    test('warehouse cannot access POS', () {
      expect(
        RolePermissions.canAccessRoute(RoutePaths.pos, UserRole.warehouse),
        false,
      );
    });

    test('salesperson cannot access suppliers', () {
      expect(
        RolePermissions.canAccessRoute(RoutePaths.suppliers, UserRole.salesperson),
        false,
      );
    });

    test('warehouse cannot access customers', () {
      expect(
        RolePermissions.canAccessRoute(RoutePaths.customers, UserRole.warehouse),
        false,
      );
    });

    test('salesperson cannot access financial report', () {
      expect(
        RolePermissions.canAccessReportPath(
          RoutePaths.reportsFinancial,
          UserRole.salesperson,
        ),
        false,
      );
    });

    test('warehouse can access inventory report', () {
      expect(
        RolePermissions.canAccessReportPath(
          RoutePaths.reportsInventory,
          UserRole.warehouse,
        ),
        true,
      );
    });

    test('salesperson cannot access inventory report', () {
      expect(
        RolePermissions.canAccessReportPath(
          RoutePaths.reportsInventory,
          UserRole.salesperson,
        ),
        false,
      );
    });
  });

  group('hub tabs', () {
    test('warehouse sees transfers but not branch finance', () {
      expect(
        RolePermissions.canAccessHubTab('branches', 'transfers', UserRole.warehouse),
        true,
      );
      expect(
        RolePermissions.canAccessHubTab('branches', 'finance', UserRole.warehouse),
        false,
      );
    });

    test('salesperson sees customers but not settlements', () {
      expect(
        RolePermissions.canAccessHubTab('customers', 'customers', UserRole.salesperson),
        true,
      );
      expect(
        RolePermissions.canAccessHubTab('customers', 'settlements', UserRole.salesperson),
        false,
      );
    });
  });

  group('actions', () {
    test('salesperson can create invoices and customers', () {
      expect(
        RolePermissions.canPerform(AppAction.invoiceCreate, UserRole.salesperson),
        true,
      );
      expect(
        RolePermissions.canPerform(AppAction.customerCreate, UserRole.salesperson),
        true,
      );
    });

    test('warehouse can adjust inventory but not sell', () {
      expect(
        RolePermissions.canPerform(AppAction.inventoryAdjust, UserRole.warehouse),
        true,
      );
      expect(
        RolePermissions.canPerform(AppAction.invoiceCreate, UserRole.warehouse),
        false,
      );
    });

    test('only admin manages users and capital edit', () {
      expect(
        RolePermissions.canPerform(AppAction.userManage, UserRole.admin),
        true,
      );
      expect(
        RolePermissions.canPerform(AppAction.userManage, UserRole.manager),
        false,
      );
      expect(
        RolePermissions.canPerform(AppAction.capitalEdit, UserRole.manager),
        false,
      );
    });

    test('only admin can reverse transfers and edit branch finance entries', () {
      expect(
        RolePermissions.canPerform(AppAction.transferReverse, UserRole.admin),
        true,
      );
      expect(
        RolePermissions.canPerform(AppAction.transferReverse, UserRole.manager),
        false,
      );
      expect(
        RolePermissions.canPerform(
          AppAction.branchFinanceEntryEdit,
          UserRole.admin,
        ),
        true,
      );
      expect(
        RolePermissions.canPerform(
          AppAction.branchFinanceEntryEdit,
          UserRole.manager,
        ),
        false,
      );
    });
  });

  group('reports by kind', () {
    test('manager can access all report kinds', () {
      for (final kind in ReportKind.values) {
        expect(
          RolePermissions.canAccessReport(kind, UserRole.manager),
          true,
        );
      }
    });
  });

  group('home route', () {
    test('salesperson lands on POS when online', () {
      expect(
        RolePermissions.homeRoute(UserRole.salesperson, isOnline: true),
        RoutePaths.pos,
      );
    });

    test('warehouse lands on parts when online', () {
      expect(
        RolePermissions.homeRoute(UserRole.warehouse, isOnline: true),
        RoutePaths.parts,
      );
    });
  });

  test('offline allows POS and sync', () {
    expect(RolePermissions.isOfflineAllowed(RoutePaths.pos), true);
    expect(RolePermissions.isOfflineAllowed(RoutePaths.sync), true);
    expect(RolePermissions.isOfflineAllowed(RoutePaths.dashboard), false);
  });
}
