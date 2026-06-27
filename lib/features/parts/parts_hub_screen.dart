import 'package:flutter/material.dart';

import '../../core/auth/role_context.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../inventory/inventory_screen.dart';
import '../shared/entity_hub_screen.dart';
import 'parts_screen.dart';

/// Parts catalog and branch stock in one navigation destination.
class PartsHubScreen extends StatelessWidget {
  const PartsHubScreen({this.initialTabId, super.key});

  final String? initialTabId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.userRole;

    final tabs = <EntityHubTab>[
      if (RolePermissions.canAccessHubTab('parts', 'parts', role))
        EntityHubTab(
          id: 'parts',
          label: l10n.partsTitle,
          child: const PartsScreen(),
        ),
      if (RolePermissions.canAccessHubTab('parts', 'stock', role))
        EntityHubTab(
          id: 'stock',
          label: l10n.inventoryTitle,
          child: const InventoryScreen(),
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
