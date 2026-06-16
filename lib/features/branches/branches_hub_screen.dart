import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/user_role.dart';
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
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canTransfer = role != UserRole.salesperson;

    final tabs = <EntityHubTab>[
      EntityHubTab(
        id: 'branches',
        label: l10n.branchesTitle,
        child: const BranchesScreen(),
      ),
      if (canTransfer) ...[
        EntityHubTab(
          id: 'transfers',
          label: l10n.transfersTitle,
          child: const TransfersScreen(),
        ),
        EntityHubTab(
          id: 'finance',
          label: l10n.branchFinanceTitle,
          child: const BranchFinanceScreen(),
        ),
      ],
    ];

    return EntityHubScreen(
      initialTabId: initialTabId,
      tabs: tabs,
    );
  }
}
