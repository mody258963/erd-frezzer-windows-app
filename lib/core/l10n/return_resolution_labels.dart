import 'package:flutter/widgets.dart';

import 'l10n_extension.dart';

import '../utils/return_approval_helper.dart';

String localizeReturnResolution(BuildContext context, String value) {
  final l = context.l10n;
  return switch (value) {
    'restock' => l.resolutionRestock,
    'credit_note' => l.resolutionCreditNote,
    'refund_cash' => l.resolutionRefundCash,
    'replace' => l.resolutionReplace,
    'writeoff' => l.resolutionWriteoff,
    'supplier_credit' => l.resolutionSupplierCredit,
    _ => value,
  };
}

String resolutionEffectHint(
  BuildContext context,
  String resolution,
  bool hasDefective,
) {
  final l = context.l10n;
  if (hasDefective && resolution == 'writeoff') {
    return l.resolutionHintWriteoffDefective;
  }
  if (resolutionRestocksStock(resolution) && resolutionRefundsCustomer(resolution)) {
    return l.resolutionHintRestockAndRefund;
  }
  if (resolutionRestocksStock(resolution)) {
    return l.resolutionHintRestockOnly;
  }
  if (resolutionRefundsCustomer(resolution)) {
    return l.resolutionHintRefundOnly;
  }
  return l.resolutionHintReplace;
}
