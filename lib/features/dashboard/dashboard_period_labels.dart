import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/dashboard/dashboard_period.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/dashboard_period_info.dart';

String dashboardProfitTitle(BuildContext context, DashboardPeriod period) {
  final l10n = context.l10n;
  return switch (period) {
    DashboardPeriod.day => l10n.todayProfit,
    DashboardPeriod.week => l10n.weeklyProfit,
    DashboardPeriod.month => l10n.monthlyProfit,
  };
}

String dashboardPeriodSalesLabel(BuildContext context, DashboardPeriod period) {
  final l10n = context.l10n;
  return switch (period) {
    DashboardPeriod.day => l10n.todaySales,
    DashboardPeriod.week => l10n.periodNetSales,
    DashboardPeriod.month => l10n.periodNetSales,
  };
}

String dashboardNetCashFlowLabel(BuildContext context, DashboardPeriod period) {
  final l10n = context.l10n;
  return switch (period) {
    DashboardPeriod.day => l10n.periodNetCashFlowDay,
    DashboardPeriod.week => l10n.periodNetCashFlowWeek,
    DashboardPeriod.month => l10n.periodNetCashFlowMonth,
  };
}

String dashboardCashInLabel(BuildContext context, DashboardPeriod period) {
  final l10n = context.l10n;
  return switch (period) {
    DashboardPeriod.day => l10n.periodCashInDay,
    DashboardPeriod.week => l10n.periodCashInWeek,
    DashboardPeriod.month => l10n.periodCashInMonth,
  };
}

String dashboardCashOutLabel(BuildContext context, DashboardPeriod period) {
  final l10n = context.l10n;
  return switch (period) {
    DashboardPeriod.day => l10n.periodCashOutDay,
    DashboardPeriod.week => l10n.periodCashOutWeek,
    DashboardPeriod.month => l10n.periodCashOutMonth,
  };
}

String dashboardSupplierPaymentsLabel(
  BuildContext context,
  DashboardPeriod period,
) {
  return context.l10n.periodSupplierPayments;
}

String dashboardPurchasesOrderedLabel(
  BuildContext context,
  DashboardPeriod period,
) {
  return context.l10n.periodPurchasesOrdered;
}

String dashboardPurchasesReceivedLabel(
  BuildContext context,
  DashboardPeriod period,
) {
  return context.l10n.periodPurchasesReceived;
}

/// Header from API `period.from` / `period.to` — single date for `day`.
String? dashboardPeriodRangeLabel(
  BuildContext context,
  DashboardPeriodInfo? info,
) {
  if (info?.from == null || info?.to == null) return null;
  final locale = Localizations.localeOf(context).toString();
  final fmt = DateFormat.yMMMd(locale);
  final from = info!.from!.toLocal();
  final to = info.to!.toLocal();

  if (info.key == DashboardPeriod.day) {
    return fmt.format(from);
  }

  final sameDay = from.year == to.year &&
      from.month == to.month &&
      from.day == to.day;
  if (sameDay) {
    return fmt.format(from);
  }

  return '${fmt.format(from)} – ${fmt.format(to)}';
}
