import 'package:flutter/widgets.dart';
import 'package:erd_rezzer/l10n/app_localizations.dart';

export 'package:erd_rezzer/l10n/app_localizations.dart';

extension AppL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String navLabel(BuildContext context, String labelKey) {
  final l = context.l10n;
  return switch (labelKey) {
    'navDashboard' => l.navDashboard,
    'navPos' => l.navPos,
    'navParts' => l.navParts,
    'navStock' => l.navStock,
    'navPartsStock' => l.navPartsStock,
    'navCustomers' => l.navCustomers,
    'navSales' => l.navSales,
    'navSettle' => l.navSettle,
    'navSupply' => l.navSupply,
    'navPurchases' => l.navPurchases,
    'navReturns' => l.navReturns,
    'navReports' => l.navReports,
    'navBranches' => l.navBranches,
    'navTransfers' => l.navTransfers,
    'navBranchFinance' => l.navBranchFinance,
    'navInstallments' => l.navInstallments,
    'navPending' => l.navPending,
    'navLocalSales' => l.navLocalSales,
    'navSettings' => l.navSettings,
    _ => labelKey,
  };
}
