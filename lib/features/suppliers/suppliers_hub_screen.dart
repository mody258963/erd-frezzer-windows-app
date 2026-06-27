import 'package:flutter/material.dart';

import '../../core/auth/role_context.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../installments/installments_screen.dart';
import '../purchases/purchases_screen.dart';
import '../shared/entity_hub_screen.dart';
import 'supplier_payables_screen.dart';
import 'suppliers_screen.dart';

/// Suppliers, purchase orders, and installment payables in one nav destination.
class SuppliersHubScreen extends StatelessWidget {
  const SuppliersHubScreen({this.initialTabId, super.key});

  final String? initialTabId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.userRole;

    final tabs = <EntityHubTab>[
      if (RolePermissions.canAccessHubTab('suppliers', 'suppliers', role))
        EntityHubTab(
          id: 'suppliers',
          label: l10n.suppliersTitle,
          child: const SuppliersScreen(),
        ),
      if (RolePermissions.canAccessHubTab('suppliers', 'purchases', role))
        EntityHubTab(
          id: 'purchases',
          label: l10n.purchasesTitle,
          child: const PurchasesScreen(),
        ),
      if (RolePermissions.canAccessHubTab('suppliers', 'payables', role))
        EntityHubTab(
          id: 'payables',
          label: l10n.supplierPayablesTitle,
          child: const SupplierPayablesScreen(),
        ),
      if (RolePermissions.canAccessHubTab('suppliers', 'installments', role))
        EntityHubTab(
          id: 'installments',
          label: l10n.installmentsTitle,
          child: const InstallmentsScreen(),
        ),
    ];

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return EntityHubScreen(
      initialTabId: initialTabId,
      tabs: tabs,
    );
  }
}
