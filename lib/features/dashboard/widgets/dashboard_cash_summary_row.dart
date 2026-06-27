import 'package:flutter/material.dart';

import '../../../core/dashboard/dashboard_period.dart';
import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/dashboard_cash_model.dart';
import '../dashboard_period_labels.dart';
import 'dashboard_section.dart';

/// Realized cash boxes — only money that already moved in or out.
class DashboardCashSummaryRow extends StatelessWidget {
  const DashboardCashSummaryRow({
    required this.cash,
    required this.period,
    super.key,
  });

  final DashboardCash cash;
  final DashboardPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final netPositive = cash.periodNetCashFlowRealized >= 0;
    final netColor = netPositive ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSection(
          title: l10n.dashboardSnapshotTitle,
          subtitle: l10n.dashboardSnapshotSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CashCard(
                    label: l10n.cashOnHandRealized,
                    value: formatMoney(context, cash.cashOnHandRealized),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                    highlight: true,
                  ),
                  _CashCard(
                    label: l10n.mustCollectCustomers,
                    value: formatMoney(context, cash.mustCollectCustomers),
                    icon: Icons.call_received_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    highlight: cash.mustCollectCustomers > 0,
                  ),
                  _CashCard(
                    label: l10n.mustPaySuppliers,
                    value: formatMoney(context, cash.mustPaySuppliers),
                    icon: Icons.call_made_outlined,
                    color: AppColors.secondary,
                    highlight: cash.mustPaySuppliers > 0,
                  ),
                  _CashCard(
                    label: dashboardNetCashFlowLabel(context, period),
                    value: formatMoney(context, cash.periodNetCashFlowRealized),
                    icon: netPositive
                        ? Icons.trending_up_outlined
                        : Icons.trending_down_outlined,
                    color: netColor,
                    highlight: cash.periodNetCashFlowRealized != 0,
                  ),
                ],
              ),
              if (cash.periodCashInRealized != 0 ||
                  cash.periodCashOutRealized != 0) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CashChip(
                      label: dashboardCashInLabel(context, period),
                      value: formatMoney(context, cash.periodCashInRealized),
                      color: AppColors.success,
                    ),
                    _CashChip(
                      label: dashboardCashOutLabel(context, period),
                      value: formatMoney(context, cash.periodCashOutRealized),
                      color: AppColors.error,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CashCard extends StatelessWidget {
  const _CashCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: highlight ? color.withValues(alpha: 0.5) : AppColors.outline,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: highlight ? color : null,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashChip extends StatelessWidget {
  const _CashChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
