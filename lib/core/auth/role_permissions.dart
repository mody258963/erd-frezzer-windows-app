import '../../core/l10n/report_labels.dart';
import '../../data/models/user_role.dart';
import '../../router/route_paths.dart';

enum AppAction {
  branchCreate,
  branchDelete,
  partCreate,
  partCategoryManage,
  partCategoryDeactivate,
  partDelete,
  inventoryAdjust,
  transferCreate,
  transferCancel,
  transferEdit,
  transferReverse,
  paymentEdit,
  customerCreate,
  customerDelete,
  invoiceCreate,
  invoiceCancel,
  settlementCreate,
  supplierCreate,
  supplierDelete,
  purchaseCreate,
  purchaseReceive,
  purchaseCancel,
  installmentPay,
  returnCreate,
  returnApprove,
  returnReject,
  branchFinanceWrite,
  branchFinanceEntryEdit,
  userManage,
  capitalEdit,
  capitalView,
}

class NavDestination {
  const NavDestination({
    required this.labelKey,
    required this.icon,
    required this.path,
    required this.routeKey,
  });

  final String labelKey;
  final int icon;
  final String path;
  final String routeKey;
}

/// Central role matrix for navigation tabs and in-app actions.
class RolePermissions {
  RolePermissions._();

  static const _all = {
    UserRole.admin,
    UserRole.manager,
    UserRole.salesperson,
    UserRole.warehouse,
  };

  static const _management = {UserRole.admin, UserRole.manager};

  static const _sales = {
    UserRole.admin,
    UserRole.manager,
    UserRole.salesperson,
  };

  static const _supply = {
    UserRole.admin,
    UserRole.manager,
    UserRole.warehouse,
  };

  /// Main nav destinations each role may see.
  static const _navRouteRoles = <String, Set<UserRole>>{
    'dashboard': _all,
    'pos': _sales,
    'parts': _all,
    'customers': _sales,
    'suppliers': _supply,
    'returns': _sales,
    'reports': {
      UserRole.admin,
      UserRole.manager,
      UserRole.salesperson,
      UserRole.warehouse,
    },
    'branches': {
      UserRole.admin,
      UserRole.manager,
      UserRole.salesperson,
      UserRole.warehouse,
    },
    'sync': _sales,
    'sales': _sales,
    'settings': _all,
  };

  static const offlineAllowedPrefixes = [
    RoutePaths.pos,
    RoutePaths.sync,
    RoutePaths.sales,
    RoutePaths.settings,
  ];

  static bool isOfflineAllowed(String path) {
    if (path.startsWith('${RoutePaths.pos}/receipt')) return true;
    return offlineAllowedPrefixes.any(
      (p) => path == p || path.startsWith('$p/'),
    );
  }

  /// First screen after login (or when a route is denied).
  static String homeRoute(UserRole role, {required bool isOnline}) {
    if (!isOnline) return RoutePaths.pos;
    return switch (role) {
      UserRole.salesperson => RoutePaths.pos,
      UserRole.warehouse => RoutePaths.parts,
      _ => RoutePaths.dashboard,
    };
  }

  static String? routeKeyForPath(String path) {
    if (path.startsWith(RoutePaths.dashboard)) return 'dashboard';
    if (path.startsWith(RoutePaths.pos)) return 'pos';
    if (path.startsWith(RoutePaths.parts) ||
        path.startsWith(RoutePaths.inventory)) {
      return 'parts';
    }
    if (path.startsWith(RoutePaths.customers) ||
        path.startsWith(RoutePaths.invoices) ||
        path.startsWith(RoutePaths.settlements)) {
      return 'customers';
    }
    if (path.startsWith(RoutePaths.suppliers) ||
        path.startsWith(RoutePaths.purchases) ||
        path.startsWith(RoutePaths.installments)) {
      return 'suppliers';
    }
    if (path.startsWith(RoutePaths.returns)) return 'returns';
    if (path.startsWith('/reports') || path.startsWith(RoutePaths.reports)) {
      return 'reports';
    }
    if (path.startsWith(RoutePaths.branches) ||
        path.startsWith(RoutePaths.transfers) ||
        path.startsWith(RoutePaths.branchFinance)) {
      return 'branches';
    }
    if (path.startsWith(RoutePaths.sync)) return 'sync';
    if (path.startsWith(RoutePaths.sales)) return 'sales';
    if (path.startsWith(RoutePaths.settings)) return 'settings';
    return null;
  }

  static bool canAccessRoute(String path, UserRole role) {
    if (path.contains('part-categories')) {
      return _management.contains(role);
    }
    if (path.contains('/settings/users')) {
      return role == UserRole.admin;
    }

    if (path.startsWith('/reports') || path.startsWith(RoutePaths.reports)) {
      return canAccessReportPath(path, role);
    }

    final key = routeKeyForPath(path);
    if (key == null) return false;
    return _navRouteRoles[key]?.contains(role) ?? false;
  }

  /// Hub sub-tabs (e.g. customers → settlements).
  static bool canAccessHubTab(
    String hubRouteKey,
    String tabId,
    UserRole role,
  ) {
    switch (hubRouteKey) {
      case 'customers':
        return switch (tabId) {
          'customers' => _sales.contains(role),
          'settlements' => canPerform(AppAction.settlementCreate, role),
          'invoices' => canPerform(AppAction.invoiceCreate, role),
          _ => false,
        };
      case 'branches':
        return switch (tabId) {
          'branches' => _navRouteRoles['branches']!.contains(role),
          'transfers' => canPerform(AppAction.transferCreate, role),
          'finance' => canPerform(AppAction.branchFinanceWrite, role),
          _ => false,
        };
      case 'suppliers':
        return switch (tabId) {
          'suppliers' => _supply.contains(role),
          'purchases' =>
            canPerform(AppAction.purchaseCreate, role) ||
                canPerform(AppAction.purchaseReceive, role),
          'payables' => canPerform(AppAction.installmentPay, role),
          'installments' => canPerform(AppAction.installmentPay, role),
          _ => false,
        };
      case 'parts':
        return switch (tabId) {
          'parts' => _navRouteRoles['parts']!.contains(role),
          'stock' => _navRouteRoles['parts']!.contains(role),
          _ => false,
        };
      default:
        return false;
    }
  }

  static bool canAccessReport(ReportKind kind, UserRole role) {
    return switch (kind) {
      ReportKind.sales => _sales.contains(role),
      ReportKind.inventory => _supply.contains(role),
      ReportKind.customers => _sales.contains(role),
      ReportKind.suppliers => _supply.contains(role),
      ReportKind.returns => _sales.contains(role),
    };
  }

  static bool canAccessFinancialReport(UserRole role) =>
      _management.contains(role);

  static bool canAccessReportPath(String path, UserRole role) {
    if (path == RoutePaths.reports) {
      return _navRouteRoles['reports']!.contains(role);
    }
    if (path.startsWith(RoutePaths.reportsFinancial)) {
      return canAccessFinancialReport(role);
    }
    if (path.startsWith(RoutePaths.reportsSales)) {
      return canAccessReport(ReportKind.sales, role);
    }
    if (path.startsWith(RoutePaths.reportsInventory)) {
      return canAccessReport(ReportKind.inventory, role);
    }
    if (path.startsWith(RoutePaths.reportsCustomers)) {
      return canAccessReport(ReportKind.customers, role);
    }
    if (path.startsWith(RoutePaths.reportsSuppliers)) {
      return canAccessReport(ReportKind.suppliers, role);
    }
    if (path.startsWith(RoutePaths.reportsReturns)) {
      return canAccessReport(ReportKind.returns, role);
    }
    if (path.startsWith(RoutePaths.reportsPartsSalesChart)) {
      return canAccessReport(ReportKind.sales, role);
    }
    return _navRouteRoles['reports']!.contains(role);
  }

  static bool canPerform(AppAction action, UserRole role) {
    switch (action) {
      case AppAction.branchCreate:
      case AppAction.branchDelete:
        return role == UserRole.admin;
      case AppAction.partCreate:
      case AppAction.partCategoryManage:
        return _management.contains(role);
      case AppAction.partCategoryDeactivate:
      case AppAction.partDelete:
        return role == UserRole.admin;
      case AppAction.inventoryAdjust:
        return role == UserRole.admin || role == UserRole.warehouse;
      case AppAction.transferCreate:
        return _supply.contains(role);
      case AppAction.transferCancel:
        return _management.contains(role);
      case AppAction.transferEdit:
      case AppAction.paymentEdit:
        return role == UserRole.admin;
      case AppAction.transferReverse:
      case AppAction.branchFinanceEntryEdit:
        return role == UserRole.admin;
      case AppAction.customerCreate:
        return _sales.contains(role);
      case AppAction.customerDelete:
        return role == UserRole.admin;
      case AppAction.invoiceCreate:
        return _sales.contains(role);
      case AppAction.invoiceCancel:
        return _management.contains(role);
      case AppAction.settlementCreate:
        return _management.contains(role);
      case AppAction.supplierCreate:
        return _management.contains(role);
      case AppAction.supplierDelete:
        return role == UserRole.admin;
      case AppAction.purchaseCreate:
      case AppAction.purchaseCancel:
      case AppAction.installmentPay:
        return _management.contains(role);
      case AppAction.purchaseReceive:
        return _supply.contains(role);
      case AppAction.returnCreate:
        return _sales.contains(role);
      case AppAction.returnApprove:
      case AppAction.returnReject:
        return _management.contains(role);
      case AppAction.branchFinanceWrite:
        return _management.contains(role);
      case AppAction.userManage:
        return role == UserRole.admin;
      case AppAction.capitalEdit:
        return role == UserRole.admin;
      case AppAction.capitalView:
        return _management.contains(role);
    }
  }

  static List<NavDestination> visibleDestinations(
    UserRole role,
    bool isOnline,
  ) {
    final all = <NavDestination>[
      const NavDestination(
        labelKey: 'navDashboard',
        icon: 0xe047,
        path: RoutePaths.dashboard,
        routeKey: 'dashboard',
      ),
      const NavDestination(
        labelKey: 'navPos',
        icon: 0xe59c,
        path: RoutePaths.pos,
        routeKey: 'pos',
      ),
      const NavDestination(
        labelKey: 'navPartsStock',
        icon: 0xf05b0,
        path: RoutePaths.parts,
        routeKey: 'parts',
      ),
      const NavDestination(
        labelKey: 'navCustomers',
        icon: 0xe7fd,
        path: RoutePaths.customers,
        routeKey: 'customers',
      ),
      const NavDestination(
        labelKey: 'navSupply',
        icon: 0xe558,
        path: RoutePaths.suppliers,
        routeKey: 'suppliers',
      ),
      const NavDestination(
        labelKey: 'navReturns',
        icon: 0xe5c9,
        path: RoutePaths.returns,
        routeKey: 'returns',
      ),
      const NavDestination(
        labelKey: 'navReports',
        icon: 0xe6c4,
        path: RoutePaths.reports,
        routeKey: 'reports',
      ),
      const NavDestination(
        labelKey: 'navBranches',
        icon: 0xe84f,
        path: RoutePaths.branches,
        routeKey: 'branches',
      ),
      const NavDestination(
        labelKey: 'navPending',
        icon: 0xe627,
        path: RoutePaths.sync,
        routeKey: 'sync',
      ),
      const NavDestination(
        labelKey: 'navLocalSales',
        icon: 0xe8cb,
        path: RoutePaths.sales,
        routeKey: 'sales',
      ),
      const NavDestination(
        labelKey: 'navSettings',
        icon: 0xe8b8,
        path: RoutePaths.settings,
        routeKey: 'settings',
      ),
    ];

    var filtered = all
        .where((d) => _navRouteRoles[d.routeKey]?.contains(role) ?? false)
        .toList();

    if (!isOnline) {
      filtered = filtered
          .where(
            (d) =>
                d.routeKey == 'pos' ||
                d.routeKey == 'sync' ||
                d.routeKey == 'sales' ||
                d.routeKey == 'settings',
          )
          .toList();
      if (!filtered.any((d) => d.routeKey == 'pos') &&
          _navRouteRoles['pos']!.contains(role)) {
        filtered.insert(
          0,
          const NavDestination(
            labelKey: 'navPos',
            icon: 0xe59c,
            path: RoutePaths.pos,
            routeKey: 'pos',
          ),
        );
      }
    }

    return filtered;
  }
}
