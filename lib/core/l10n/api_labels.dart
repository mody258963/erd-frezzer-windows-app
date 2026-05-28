import 'package:flutter/widgets.dart';

import 'l10n_extension.dart';

/// Localizes common API enum strings (status, payment type, customer type).
String localizeApiStatus(BuildContext context, String? status) {
  final s = (status ?? '').toLowerCase().replaceAll(' ', '_');
  final l = context.l10n;
  return switch (s) {
    'pending' => l.statusPending,
    'paid' => l.statusPaid,
    'approved' => l.statusApproved,
    'reject' || 'rejected' => l.statusRejected,
    'completed' || 'complete' => l.statusCompleted,
    'cancelled' || 'canceled' => l.statusCancelled,
    'received' => l.receive,
    '' => '—',
    _ => status ?? '—',
  };
}

String localizePaymentType(BuildContext context, String? type) {
  final t = (type ?? '').toLowerCase();
  final l = context.l10n;
  return switch (t) {
    'cash' => l.cash,
    'credit' => l.credit,
    'installments' || 'installment' => l.paymentInstallments,
    'immediate' => l.paymentImmediate,
    '' => '—',
    _ => type ?? '—',
  };
}

String localizeCustomerType(BuildContext context, String? type) {
  return localizePaymentType(context, type);
}

String localizeReturnType(BuildContext context, String? type) {
  final t = (type ?? '').toLowerCase();
  final l = context.l10n;
  return switch (t) {
    'customer_return' => l.returnTypeCustomer,
    'supplier_return' => l.returnTypeSupplier,
    '' => '—',
    _ => type ?? '—',
  };
}

String localizeReturnCondition(BuildContext context, String? condition) {
  final c = (condition ?? '').toLowerCase();
  final l = context.l10n;
  return switch (c) {
    'sellable' => l.conditionSellable,
    'defective' => l.conditionDefective,
    '' => '—',
    _ => condition ?? '—',
  };
}

/// Arabic labels for [PartUnit] enum values (`pc`, `kg`, …).
String localizePartUnitLabel(
  BuildContext context,
  String value,
  String apiLabel,
) {
  final l = context.l10n;
  return switch (value) {
    'pc' => l.unitPc,
    'box' => l.unitBox,
    'set' => l.unitSet,
    'kg' => l.unitKg,
    'm' => l.unitM,
    'l' => l.unitL,
    'roll' => l.unitRoll,
    'pack' => l.unitPack,
    _ => apiLabel,
  };
}

String localizeBranchEntryType(BuildContext context, String? type) {
  final t = (type ?? '').toLowerCase();
  final l = context.l10n;
  return switch (t) {
    'charge' => l.entryTypeCharge,
    'payment' => l.entryTypePayment,
    '' => '—',
    _ => type ?? '—',
  };
}

String localizeMovementType(BuildContext context, String? type) {
  final t = (type ?? '').toLowerCase();
  final l = context.l10n;
  return switch (t) {
    'purchase_in' => l.movementPurchaseIn,
    'sale_out' => l.movementSaleOut,
    'transfer_in' => l.movementTransferIn,
    'transfer_out' => l.movementTransferOut,
    'return_in' => l.movementReturnIn,
    'return_out' => l.movementReturnOut,
    'adjustment' => l.movementAdjustment,
    '' => '—',
    _ => type ?? '—',
  };
}

String formatMoney(BuildContext context, num? value) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(2)} ${context.l10n.currencyEgp}';
}

/// Maps POS bloc error codes to localized messages.
String localizePosError(BuildContext context, String? error) {
  if (error == null || error.isEmpty) return '';
  final l = context.l10n;
  final parts = error.split(':');
  final code = parts.length > 1 ? parts.sublist(1).join(':') : '';
  return switch (parts.first) {
    'no_stock' => l.noStockForPart(code),
    'insufficient_stock' => l.insufficientStockFor(code),
    'select_customer' => l.selectCustomerAndItems,
    'credit_blocked' => l.creditSalesBlockedOffline,
    'credit_unavailable' => l.creditSalesUnavailableOffline,
    'insufficient_stock_generic' => l.insufficientStock,
    'invalid_line_price' => l.invalidLinePrice,
    _ => error,
  };
}
