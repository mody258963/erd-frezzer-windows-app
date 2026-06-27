import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/l10n/report_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_role.dart';
import '../../router/route_paths.dart';
import '../shared/page_header.dart';

/// Landing page: pick which report to open.
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role =
        context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;

    final items = <_ReportCardData>[
      if (RolePermissions.canAccessFinancialReport(role))
        _ReportCardData(
          kind: ReportKind.sales,
          icon: Icons.account_balance_outlined,
          title: l10n.financialReportTitle,
          description: l10n.reportDescFinancial,
          path: RoutePaths.reportsFinancial,
          color: AppColors.success,
        ),
      if (RolePermissions.canAccessReport(ReportKind.sales, role))
        _ReportCardData(
          kind: ReportKind.sales,
          icon: Icons.point_of_sale_outlined,
          title: l10n.salesReportTitle,
          description: l10n.reportDescSales,
          path: RoutePaths.reportsSales,
          color: AppColors.primary,
        ),
      if (RolePermissions.canAccessReport(ReportKind.inventory, role))
        _ReportCardData(
          kind: ReportKind.inventory,
          icon: Icons.inventory_2_outlined,
          title: l10n.inventoryReportTitle,
          description: l10n.reportDescInventory,
          path: RoutePaths.reportsInventory,
          color: AppColors.secondary,
        ),
      if (RolePermissions.canAccessReport(ReportKind.customers, role))
        _ReportCardData(
          kind: ReportKind.customers,
          icon: Icons.people_outline,
          title: l10n.customersReportTitle,
          description: l10n.reportDescCustomers,
          path: RoutePaths.reportsCustomers,
          color: AppColors.tertiary,
        ),
      if (RolePermissions.canAccessReport(ReportKind.suppliers, role))
        _ReportCardData(
          kind: ReportKind.suppliers,
          icon: Icons.local_shipping_outlined,
          title: l10n.suppliersReportTitle,
          description: l10n.reportDescSuppliers,
          path: RoutePaths.reportsSuppliers,
          color: AppColors.warning,
        ),
      if (RolePermissions.canAccessReport(ReportKind.returns, role))
        _ReportCardData(
          kind: ReportKind.returns,
          icon: Icons.undo_outlined,
          title: l10n.returnsReportTitle,
          description: l10n.reportDescReturns,
          path: RoutePaths.reportsReturns,
          color: AppColors.error,
        ),
      if (RolePermissions.canAccessReport(ReportKind.sales, role))
        _ReportCardData(
          kind: ReportKind.sales,
          icon: Icons.show_chart_outlined,
          title: l10n.partsSalesChartTitle,
          description: l10n.reportDescPartsSalesChart,
          path: RoutePaths.reportsPartsSalesChart,
          color: AppColors.primary,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.reportsHubTitle,
          subtitle: l10n.reportsHubSubtitle,
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    l10n.noData,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _ReportCard(
                        data: items[i],
                        onTap: () => context.go(items[i].path),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReportCardData {
  const _ReportCardData({
    required this.kind,
    required this.icon,
    required this.title,
    required this.description,
    required this.path,
    required this.color,
  });

  final ReportKind kind;
  final IconData icon;
  final String title;
  final String description;
  final String path;
  final Color color;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.data, required this.onTap});

  final _ReportCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
