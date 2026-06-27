import 'package:flutter/material.dart';

import '../../core/auth/role_context.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../branch_finance/branch_finance_screen.dart';
import '../shared/entity_hub_screen.dart';
import '../transfers/transfers_screen.dart';
import 'branches_screen.dart';

/// Branches, stock transfers, and inter-branch finance in one nav destination.
class BranchesHubScreen extends StatelessWidget {
  const BranchesHubScreen({this.initialTabId, super.key});

  final String? initialTabId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.userRole;

    final tabs = <EntityHubTab>[
      if (RolePermissions.canAccessHubTab('branches', 'branches', role))
        EntityHubTab(
          id: 'branches',
          label: l10n.branchesTitle,
          child: const BranchesScreen(),
        ),
      if (RolePermissions.canAccessHubTab('branches', 'transfers', role))
        EntityHubTab(
          id: 'transfers',
          label: l10n.transfersTitle,
          child: const TransfersScreen(),
        ),
      if (RolePermissions.canAccessHubTab('branches', 'finance', role))
        EntityHubTab(
          id: 'finance',
          label: l10n.branchFinanceTitle,
          child: const BranchFinanceScreen(),
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
