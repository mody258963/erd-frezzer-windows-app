import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../router/route_paths.dart';
import '../dashboard_summary_utils.dart';
import 'dashboard_section.dart';

/// Purchases, supplier debt, and installments from summary + payables API.
class DashboardSupplierPanel extends StatelessWidget {
  const DashboardSupplierPanel({
    required this.summary,
    required this.payables,
    super.key,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic>? payables;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final supplierDebt = summaryNum(summary, 'total_supplier_debt');
    final unpaidTotal = summaryNum(summary, 'unpaid_installments_total');
    final unpaidCount = summaryInt(summary, 'unpaid_installments_count');
    final overdueTotal = summaryNum(summary, 'overdue_installments_total');
    final overdueCount = summaryOverdueInstallmentCount(summary);
    final weeklyPaid = summaryNum(summary, 'weekly_supplier_payments');
    final weeklyOrdered = summaryNum(summary, 'weekly_purchases_ordered');
    final weeklyReceived = summaryNum(summary, 'weekly_purchases_received');

    final hasSummary = supplierDebt > 0 ||
        unpaidTotal > 0 ||
        weeklyOrdered > 0 ||
        weeklyPaid > 0;
    final overdueList = payablesInstallmentList(payables, 'overdue');
    final upcomingList = payablesInstallmentList(payables, 'upcoming');

    if (!hasSummary && overdueList.isEmpty && upcomingList.isEmpty) {
      return const SizedBox.shrink();
    }

    return DashboardSection(
      title: l10n.dashboardPurchasesTitle,
      subtitle: l10n.dashboardPurchasesSubtitle,
      trailing: TextButton(
        onPressed: () => context.go('${RoutePaths.suppliers}?tab=installments'),
        child: Text(l10n.viewInstallments),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (supplierDebt > 0)
                    _StatChip(
                      label: l10n.totalSupplierDebt,
                      value: formatMoney(context, supplierDebt),
                      icon: Icons.account_balance_outlined,
                      color: AppColors.secondary,
                    ),
                  if (unpaidTotal > 0)
                    _StatChip(
                      label: l10n.unpaidInstallmentsTotal,
                      value: formatMoney(context, unpaidTotal),
                      subtitle: unpaidCount > 0 ? '$unpaidCount' : null,
                      icon: Icons.payments_outlined,
                      color: AppColors.warning,
                    ),
                  if (overdueTotal > 0 || overdueCount > 0)
                    _StatChip(
                      label: l10n.overdueInstallmentsTotal,
                      value: formatMoney(context, overdueTotal),
                      subtitle: overdueCount > 0 ? '$overdueCount' : null,
                      icon: Icons.schedule_rounded,
                      color: AppColors.error,
                      highlight: true,
                    ),
                  if (weeklyPaid > 0)
                    _StatChip(
                      label: l10n.weeklySupplierPayments,
                      value: formatMoney(context, weeklyPaid),
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                  if (weeklyOrdered > 0)
                    _StatChip(
                      label: l10n.weeklyPurchasesOrdered,
                      value: formatMoney(context, weeklyOrdered),
                      icon: Icons.shopping_cart_outlined,
                    ),
                  if (weeklyReceived > 0)
                    _StatChip(
                      label: l10n.weeklyPurchasesReceived,
                      value: formatMoney(context, weeklyReceived),
                      icon: Icons.inventory_outlined,
                    ),
                ],
              ),
              if (overdueList.isNotEmpty || upcomingList.isNotEmpty) ...[
                const SizedBox(height: 16),
                if (overdueList.isNotEmpty) ...[
                  Text(
                    l10n.payablesOverdueInstallments,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                  ),
                  const SizedBox(height: 6),
                  ...overdueList.take(5).map(
                        (row) => _InstallmentTile(row: row, overdue: true),
                      ),
                ],
                if (upcomingList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.payablesUpcomingInstallments,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  ...upcomingList.take(5).map(
                        (row) => _InstallmentTile(row: row, overdue: false),
                      ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? c : AppColors.outline,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            subtitle != null ? '$label ($subtitle)' : label,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.row, required this.overdue});

  final Map<String, dynamic> row;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final supplier = row['supplier_name'] as String? ??
        (row['supplier'] is Map
            ? (row['supplier'] as Map)['name']
            : null) ??
        '—';
    final amount = row['amount'] ?? row['total'];
    final due = row['due_date'] as String? ?? '';
    final dueLabel = due.length >= 10 ? due.substring(0, 10) : due;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        overdue ? Icons.warning_amber_rounded : Icons.event_outlined,
        color: overdue ? AppColors.error : null,
        size: 20,
      ),
      title: Text(supplier, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(dueLabel.isNotEmpty ? dueLabel : '—'),
      trailing: Text(
        formatMoney(context, amount is num ? amount : num.tryParse('$amount')),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      titleTextStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
