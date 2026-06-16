import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/user_role.dart';
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
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;

    final tabs = <EntityHubTab>[
      EntityHubTab(
        id: 'customers',
        label: l10n.customersTitle,
        child: const CustomersScreen(),
      ),
      if (role == UserRole.admin || role == UserRole.manager)
        EntityHubTab(
          id: 'settlements',
          label: l10n.settlementsTitle,
          child: const SettlementsScreen(),
        ),
      if (role != UserRole.warehouse)
        EntityHubTab(
          id: 'invoices',
          label: l10n.invoicesTitle,
          child: const InvoicesScreen(),
        ),
    ];

    return EntityHubScreen(
      initialTabId: initialTabId,
      tabs: tabs,
    );
  }
}
