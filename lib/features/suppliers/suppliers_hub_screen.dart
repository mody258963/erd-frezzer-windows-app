import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/user_role.dart';
import '../installments/installments_screen.dart';
import '../purchases/purchases_screen.dart';
import '../shared/entity_hub_screen.dart';
import 'suppliers_screen.dart';

/// Suppliers, purchase orders, and installment payables in one nav destination.
class SuppliersHubScreen extends StatelessWidget {
  const SuppliersHubScreen({this.initialTabId, super.key});

  final String? initialTabId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;

    if (role == UserRole.salesperson) {
      return const SizedBox.shrink();
    }

    return EntityHubScreen(
      initialTabId: initialTabId,
      tabs: [
        EntityHubTab(
          id: 'suppliers',
          label: l10n.suppliersTitle,
          child: const SuppliersScreen(),
        ),
        EntityHubTab(
          id: 'purchases',
          label: l10n.purchasesTitle,
          child: const PurchasesScreen(),
        ),
        EntityHubTab(
          id: 'installments',
          label: l10n.installmentsTitle,
          child: const InstallmentsScreen(),
        ),
      ],
    );
  }
}
