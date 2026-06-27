import 'package:flutter/material.dart';

import '../../core/auth/role_context.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../invoices/invoices_screen.dart';
import '../settlements/settlements_screen.dart';
import '../shared/entity_hub_screen.dart';
import 'customers_screen.dart';

/// Customers, credit settlements, and sales invoices in one nav destination.
class CustomersHubScreen extends StatelessWidget {
  const CustomersHubScreen({this.initialTabId, super.key});

  final String? initialTabId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.userRole;

    final tabs = <EntityHubTab>[
      if (RolePermissions.canAccessHubTab('customers', 'customers', role))
        EntityHubTab(
          id: 'customers',
          label: l10n.customersTitle,
          child: const CustomersScreen(),
        ),
      if (RolePermissions.canAccessHubTab('customers', 'settlements', role))
        EntityHubTab(
          id: 'settlements',
          label: l10n.settlementsTitle,
          child: const SettlementsScreen(),
        ),
      if (RolePermissions.canAccessHubTab('customers', 'invoices', role))
        EntityHubTab(
          id: 'invoices',
          label: l10n.invoicesTitle,
          child: const InvoicesScreen(),
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
