import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dashboard/dashboard_period.dart';
import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/capital_model.dart';
import '../../../data/models/dashboard_cash_model.dart';
import '../../../router/route_paths.dart';
import '../../shared/business_capital_breakdown.dart';
import '../dashboard_period_labels.dart';
import '../dashboard_summary_utils.dart';
import 'dashboard_section.dart';

/// Unified financial overview: capital, cash, obligations, and period purchases.
class DashboardFinanceHub extends StatelessWidget {
  const DashboardFinanceHub({
    required this.summary,
    required this.period,
    this.cash,
    this.receivables = const [],
    this.payables,
    super.key,
  });

  final Map<String, dynamic> summary;
  final DashboardPeriod period;
  final DashboardCash? cash;
  final List<Map<String, dynamic>> receivables;
  final Map<String, dynamic>? payables;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width > 900;

    final businessCapital = summary['business_capital'];
    final showCapital = businessCapital != null;
    final currency = '${summary['capital_currency'] ?? 'EGP'}';
    final stock = summaryNum(summary, 'total_stock_value_cost');
    final cashOnHand = cash?.cashOnHandRealized ??
        summaryNum(summary, 'cash_on_hand_realized');
    final capitalTotal = businessCapital is num
        ? businessCapital.toDouble()
        : double.tryParse('$businessCapital') ?? stock + cashOnHand;

    final mustCollect =
        cash?.mustCollectCustomers ?? summaryNum(summary, 'total_receivables');
    final mustPay =
        cash?.mustPaySuppliers ?? summaryNum(summary, 'total_supplier_debt');
    final supplierDebt = summaryNum(summary, 'total_supplier_debt');
    final overdueCount = summaryOverdueInstallmentCount(summary);
    final overdueTotal = summaryNum(summary, 'overdue_installments_total');

    final hasCashSection = cash != null ||
        summary.containsKey('cash_on_hand_realized') ||
        summary.containsKey('must_collect_customers') ||
        summary.containsKey('must_pay_suppliers') ||
        summary.containsKey('total_receivables');

    final periodPaid = summaryPeriodNum(summary, 'supplier_payments');
    final periodOrdered = summaryPeriodNum(summary, 'purchases_ordered');
    final periodReceived = summaryPeriodNum(summary, 'purchases_received');
    final showPeriodActivity =
        periodPaid > 0 || periodOrdered > 0 || periodReceived > 0;

    final payablesList = (payables?['suppliers'] as List<dynamic>?) ??
        (payables?['items'] as List<dynamic>?) ??
        [];
    final creditors = payablesList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final overdueInstallments = payablesInstallmentList(payables, 'overdue');

    if (!showCapital && !hasCashSection && mustCollect <= 0 && mustPay <= 0) {
      return const SizedBox.shrink();
    }

    Widget capitalBlock() {
      if (!showCapital) return const SizedBox.shrink();
      var stockVal = stock;
      var cashVal = cashOnHand;
      final snapRaw = summary['financing_snapshot'];
      if (stockVal <= 0 && snapRaw is Map<String, dynamic>) {
        final snap = FinancingSnapshot.fromJson(snapRaw);
        if (snap.inventoryAtCost > 0) stockVal = snap.inventoryAtCost;
        if (cashVal <= 0) cashVal = snap.cashOnHandRealized;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.savings_outlined, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.businessCapitalTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(RoutePaths.settings),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l10n.settingsTitle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BusinessCapitalBreakdown(
            businessCapital: capitalTotal > 0 ? capitalTotal : stockVal + cashVal,
            inventoryAtCost: stockVal,
            cashOnHandRealized: cashVal,
            currency: currency,
            compact: true,
          ),
        ],
      );
    }

    Widget cashBlock() {
      final periodCashIn = cash?.periodCashInRealized ??
          summaryPeriodNum(summary, 'cash_in_realized');
      final periodCashOut = cash?.periodCashOutRealized ??
          summaryPeriodNum(summary, 'cash_out_realized');
      final net = cash?.periodNetCashFlowRealized ??
          summaryPeriodNum(summary, 'net_cash_flow_realized');
      final netPositive = net >= 0;
      final netColor = netPositive ? AppColors.success : AppColors.error;
      final showPeriodFlow =
          periodCashIn != 0 || periodCashOut != 0 || net != 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.dashboardSnapshotTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dashboardSnapshotSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          _MetricHighlight(
            label: l10n.cashOnHandRealized,
            value: formatMoney(context, cashOnHand),
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.mustCollectCustomers,
                  value: formatMoney(context, mustCollect),
                  icon: Icons.call_received_outlined,
                  color: scheme.primary,
                  highlight: mustCollect > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: l10n.mustPaySuppliers,
                  value: formatMoney(context, mustPay),
                  icon: Icons.call_made_outlined,
                  color: AppColors.secondary,
                  highlight: mustPay > 0,
                ),
              ),
            ],
          ),
          if (showPeriodFlow) ...[
            const SizedBox(height: 16),
            Text(
              dashboardNetCashFlowLabel(context, period),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: netColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: netColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.periodNetCashFlowRealized,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        formatMoney(context, net),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: netColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${dashboardCashInLabel(context, period)}: ${formatMoney(context, periodCashIn)}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${dashboardCashOutLabel(context, period)}: ${formatMoney(context, periodCashOut)}',
                          textAlign: TextAlign.end,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    Widget obligationsRow() {
      return wide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ObligationsColumn(
                      title: l10n.receivablesTitle,
                      totalLabel: l10n.mustCollectCustomers,
                      total: mustCollect,
                      topLabel: l10n.topDebtors,
                      items: receivables,
                      emptyMessage: l10n.noDebtors,
                      accentColor: scheme.primary,
                      nameKeys: const ['name', 'customer_name'],
                    ),
                  ),
                  const VerticalDivider(width: 24),
                  Expanded(
                    child: _ObligationsColumn(
                      title: l10n.payablesTitle,
                      totalLabel: l10n.totalSupplierDebt,
                      total: supplierDebt > 0 ? supplierDebt : mustPay,
                      topLabel: l10n.topCreditors,
                      items: creditors,
                      emptyMessage: l10n.noCreditors,
                      accentColor: AppColors.secondary,
                      nameKeys: const ['name', 'supplier_name'],
                      badge: overdueCount > 0
                          ? '${l10n.overdueInstallments}: $overdueCount · ${formatMoney(context, overdueTotal)}'
                          : null,
                      trailing: TextButton(
                        onPressed: () =>
                            context.go('${RoutePaths.suppliers}?tab=payables'),
                        child: Text(l10n.viewInstallments),
                      ),
                      extraTiles: overdueInstallments.take(3).map((row) {
                        final supplier = row['supplier_name'] as String? ??
                            (row['supplier'] is Map
                                ? (row['supplier'] as Map)['name']
                                : null) ??
                            '—';
                        final amount = row['amount'] ?? row['total'];
                        return _CompactListTile(
                          leading: Icons.warning_amber_rounded,
                          leadingColor: AppColors.error,
                          title: supplier,
                          trailing: formatMoney(
                            context,
                            amount is num ? amount : num.tryParse('$amount'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ObligationsColumn(
                  title: l10n.receivablesTitle,
                  totalLabel: l10n.mustCollectCustomers,
                  total: mustCollect,
                  topLabel: l10n.topDebtors,
                  items: receivables,
                  emptyMessage: l10n.noDebtors,
                  accentColor: scheme.primary,
                  nameKeys: const ['name', 'customer_name'],
                ),
                const SizedBox(height: 20),
                _ObligationsColumn(
                  title: l10n.payablesTitle,
                  totalLabel: l10n.totalSupplierDebt,
                  total: supplierDebt > 0 ? supplierDebt : mustPay,
                  topLabel: l10n.topCreditors,
                  items: creditors,
                  emptyMessage: l10n.noCreditors,
                  accentColor: AppColors.secondary,
                  nameKeys: const ['name', 'supplier_name'],
                  badge: overdueCount > 0
                      ? '${l10n.overdueInstallments}: $overdueCount'
                      : null,
                  trailing: TextButton(
                    onPressed: () =>
                        context.go('${RoutePaths.suppliers}?tab=payables'),
                    child: Text(l10n.viewInstallments),
                  ),
                  extraTiles: overdueInstallments.take(3).map((row) {
                    final supplier = row['supplier_name'] as String? ?? '—';
                    final amount = row['amount'] ?? row['total'];
                    return _CompactListTile(
                      leading: Icons.warning_amber_rounded,
                      leadingColor: AppColors.error,
                      title: supplier,
                      trailing: formatMoney(
                        context,
                        amount is num ? amount : num.tryParse('$amount'),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
    }

    return DashboardSection(
      title: l10n.dashboardFinanceOverview,
      subtitle: l10n.dashboardFinanceOverviewSubtitle,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCapital || hasCashSection) ...[
                wide && showCapital && hasCashSection
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: capitalBlock()),
                            const VerticalDivider(width: 24),
                            Expanded(child: cashBlock()),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showCapital) capitalBlock(),
                          if (showCapital && hasCashSection)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                          if (hasCashSection) cashBlock(),
                        ],
                      ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
              ],
              obligationsRow(),
              if (showPeriodActivity) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Text(
                  l10n.dashboardPeriodActivity,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (periodOrdered > 0)
                      _ActivityChip(
                        label: dashboardPurchasesOrderedLabel(context, period),
                        value: formatMoney(context, periodOrdered),
                        icon: Icons.shopping_cart_outlined,
                      ),
                    if (periodReceived > 0)
                      _ActivityChip(
                        label: dashboardPurchasesReceivedLabel(context, period),
                        value: formatMoney(context, periodReceived),
                        icon: Icons.inventory_outlined,
                      ),
                    if (periodPaid > 0)
                      _ActivityChip(
                        label: dashboardSupplierPaymentsLabel(context, period),
                        value: formatMoney(context, periodPaid),
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricHighlight extends StatelessWidget {
  const _MetricHighlight({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.45) : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ObligationsColumn extends StatelessWidget {
  const _ObligationsColumn({
    required this.title,
    required this.totalLabel,
    required this.total,
    required this.topLabel,
    required this.items,
    required this.emptyMessage,
    required this.accentColor,
    required this.nameKeys,
    this.badge,
    this.trailing,
    this.extraTiles = const [],
  });

  final String title;
  final String totalLabel;
  final num total;
  final String topLabel;
  final List<Map<String, dynamic>> items;
  final String emptyMessage;
  final Color accentColor;
  final List<String> nameKeys;
  final String? badge;
  final Widget? trailing;
  final List<Widget> extraTiles;

  @override
  Widget build(BuildContext context) {
    final top = items.take(5).toList();
    final maxBalance = top.isEmpty
        ? 1.0
        : top
            .map(
              (e) => (e['outstanding_balance'] ??
                      e['balance'] ??
                      e['debt'] ??
                      0) as num,
            )
            .fold<num>(0, (a, b) => a > b ? a : b)
            .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: accentColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        Text(
          formatMoney(context, total),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
        ),
        Text(
          totalLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (badge != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          topLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        if (top.isEmpty && extraTiles.isEmpty)
          Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else ...[
          for (final item in top)
            _BalanceRow(
              name: _nameFrom(item, nameKeys),
              amount: (item['outstanding_balance'] ??
                  item['balance'] ??
                  item['debt'] ??
                  0) as num,
              maxAmount: maxBalance,
              color: accentColor,
            ),
          ...extraTiles,
        ],
      ],
    );
  }

  String _nameFrom(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final v = item[key];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return '—';
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.name,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  final String name;
  final num amount;
  final double maxAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatMoney(context, amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: AppColors.outline.withValues(alpha: 0.25),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactListTile extends StatelessWidget {
  const _CompactListTile({
    required this.leading,
    required this.title,
    required this.trailing,
    this.leadingColor,
  });

  final IconData leading;
  final Color? leadingColor;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(leading, size: 16, color: leadingColor,),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
          ),
        ],
      ),
    );
  }
}
