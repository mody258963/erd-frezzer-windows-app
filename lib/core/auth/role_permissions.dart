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
  paymentEdit,
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

class RolePermissions {
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

  static bool canAccessRoute(String path, UserRole role) {
    if (path.startsWith(RoutePaths.dashboard)) {
      return true;
    }
    if (path.startsWith(RoutePaths.branches)) {
      return true;
    }
    if (path.startsWith(RoutePaths.parts)) {
      return true;
    }
    if (path.startsWith(RoutePaths.inventory)) {
      return true;
    }
    if (path.startsWith(RoutePaths.transfers) ||
        path.startsWith(RoutePaths.branchFinance)) {
      return role != UserRole.salesperson;
    }
    if (path.startsWith(RoutePaths.customers)) {
      return role != UserRole.warehouse;
    }
    if (path.startsWith(RoutePaths.pos) ||
        path.startsWith(RoutePaths.invoices) ||
        path.startsWith(RoutePaths.sales)) {
      return role != UserRole.warehouse;
    }
    if (path.startsWith(RoutePaths.sync)) {
      return role != UserRole.warehouse;
    }
    if (path.startsWith(RoutePaths.settlements)) {
      return role == UserRole.admin || role == UserRole.manager;
    }
    if (path.startsWith(RoutePaths.suppliers) ||
        path.startsWith(RoutePaths.purchases) ||
        path.startsWith(RoutePaths.installments)) {
      return role != UserRole.salesperson;
    }
    if (path.startsWith(RoutePaths.returns)) {
      return role != UserRole.warehouse;
    }
    if (path.startsWith('/reports')) {
      return true;
    }
    if (path.contains('part-categories')) {
      return role == UserRole.admin || role == UserRole.manager;
    }
    if (path.contains('/settings/users')) {
      return role == UserRole.admin;
    }
    if (path.startsWith(RoutePaths.settings)) {
      return true;
    }
    return true;
  }

  static bool canPerform(AppAction action, UserRole role) {
    switch (action) {
      case AppAction.branchCreate:
      case AppAction.branchDelete:
        return role == UserRole.admin;
      case AppAction.partCreate:
      case AppAction.partCategoryManage:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.partCategoryDeactivate:
        return role == UserRole.admin;
      case AppAction.partDelete:
        return role == UserRole.admin;
      case AppAction.inventoryAdjust:
        return role == UserRole.admin || role == UserRole.warehouse;
      case AppAction.transferCreate:
        return role != UserRole.salesperson;
      case AppAction.transferCancel:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.transferEdit:
      case AppAction.paymentEdit:
        return role == UserRole.admin;
      case AppAction.customerDelete:
        return role == UserRole.admin;
      case AppAction.invoiceCreate:
        return role != UserRole.warehouse;
      case AppAction.invoiceCancel:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.settlementCreate:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.supplierCreate:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.supplierDelete:
        return role == UserRole.admin;
      case AppAction.purchaseCreate:
      case AppAction.purchaseCancel:
      case AppAction.installmentPay:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.purchaseReceive:
        return role != UserRole.salesperson;
      case AppAction.returnCreate:
        return role != UserRole.warehouse;
      case AppAction.returnApprove:
      case AppAction.returnReject:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.branchFinanceWrite:
        return role == UserRole.admin || role == UserRole.manager;
      case AppAction.userManage:
        return role == UserRole.admin;
      case AppAction.capitalEdit:
        return role == UserRole.admin;
      case AppAction.capitalView:
        return role == UserRole.admin || role == UserRole.manager;
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

    var filtered = all.where((d) => canAccessRoute(d.path, role)).toList();

    if (!isOnline) {
      filtered = filtered
          .where(
            (d) =>
                d.routeKey == 'pos' ||
                d.routeKey == 'sync' ||
                d.routeKey == 'sales',
          )
          .toList();
      if (!filtered.any((d) => d.routeKey == 'pos')) {
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
