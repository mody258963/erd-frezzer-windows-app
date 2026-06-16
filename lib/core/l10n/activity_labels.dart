import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n_extension.dart';

/// User-facing label for a dashboard activity log row.
class ActivityPresentation {
  const ActivityPresentation({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
}

ActivityPresentation presentActivity(
  BuildContext context,
  Map<String, dynamic> row,
) {
  final l = context.l10n;
  final action = _norm(row['action'] ?? row['type'] ?? '');
  final entity = _norm(row['entity_type'] ?? row['entity'] ?? '');
  final key = action.isNotEmpty && entity.isNotEmpty ? '$action.$entity' : action;

  final detail = _detailFromRow(row);
  final color = _colorForEntity(entity);
  final icon = _iconForKey(key, entity);

  final title = switch (key) {
    'invoice.create' || 'sale.create' => l.activityInvoiceCreated,
    'invoice.cancel' || 'invoice.void' => l.activityInvoiceCancelled,
    'invoice.update' => l.activityInvoiceUpdated,
    'inventory.adjust' || 'stock.adjust' => l.activityInventoryAdjusted,
    'purchase.create' => l.activityPurchaseCreated,
    'purchase.receive' => l.activityPurchaseReceived,
    'customer.create' => l.activityCustomerCreated,
    'customer.update' => l.activityCustomerUpdated,
    'settlement.create' => l.activitySettlementRecorded,
    'transfer.create' => l.activityTransferCreated,
    'transfer.complete' => l.activityTransferCompleted,
    'return.approve' => l.activityReturnApproved,
    'return.reject' => l.activityReturnRejected,
    'part.create' => l.activityPartCreated,
    'part.update' => l.activityPartUpdated,
    'supplier.create' => l.activitySupplierCreated,
    'sync.complete' => l.activitySyncCompleted,
    'owner.cash_out' => l.activityOwnerCashOut,
    _ => l.activityGeneric(
      _humanizeToken(action.isNotEmpty ? action : key),
      _humanizeEntity(context, entity),
    ),
  };

  return ActivityPresentation(
    title: title,
    subtitle: detail,
    icon: icon,
    color: color,
  );
}

String formatActivityTimestamp(BuildContext context, String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dt);
  } catch (_) {
    return raw;
  }
}

String? _detailFromRow(Map<String, dynamic> row) {
  final parts = <String>[
    if (row['description'] != null) '${row['description']}',
    if (row['reference'] != null) '${row['reference']}',
    if (row['user_name'] != null) '${row['user_name']}',
    if (row['branch_name'] != null) '${row['branch_name']}',
  ];
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

String _norm(dynamic v) => '$v'.trim().toLowerCase().replaceAll(' ', '_');

String _humanizeToken(String token) {
  if (token.isEmpty) return '—';
  return token.replaceAll('.', ' ').replaceAll('_', ' ');
}

String _humanizeEntity(BuildContext context, String entity) {
  if (entity.isEmpty) return '';
  final l = context.l10n;
  return switch (entity) {
    'invoice' || 'sale' || 'sales' => l.entityInvoice,
    'stock' || 'inventory' => l.entityStock,
    'customer' || 'customers' => l.entityCustomer,
    'purchase' || 'purchases' => l.entityPurchase,
    'supplier' || 'suppliers' => l.entitySupplier,
    'part' || 'parts' => l.entityPart,
    'transfer' || 'transfers' => l.entityTransfer,
    'return' || 'returns' => l.entityReturn,
    'settlement' || 'settlements' => l.entitySettlement,
    'branch' || 'branches' => l.entityBranch,
    _ => _humanizeToken(entity),
  };
}

Color _colorForEntity(String entity) {
  return switch (entity) {
    'invoice' || 'sale' || 'sales' => const Color(0xFF4F46E5),
    'stock' || 'inventory' => const Color(0xFFD97706),
    'customer' || 'customers' => const Color(0xFF0891B2),
    'purchase' || 'purchases' => const Color(0xFF7C3AED),
    'return' || 'returns' => const Color(0xFFDC2626),
    'transfer' || 'transfers' => const Color(0xFF059669),
    _ => const Color(0xFF64748B),
  };
}

IconData _iconForKey(String key, String entity) {
  if (key.contains('invoice') || key.contains('sale')) {
    return Icons.receipt_long_outlined;
  }
  if (key.contains('inventory') || key.contains('stock')) {
    return Icons.inventory_2_outlined;
  }
  if (key.contains('customer')) return Icons.person_outline;
  if (key.contains('purchase')) return Icons.shopping_cart_outlined;
  if (key.contains('return')) return Icons.undo_outlined;
  if (key.contains('transfer')) return Icons.swap_horiz;
  if (key.contains('settlement')) return Icons.payments_outlined;
  if (key.contains('part')) return Icons.build_outlined;
  if (key.contains('supplier')) return Icons.local_shipping_outlined;
  if (key.contains('sync')) return Icons.cloud_done_outlined;
  if (key.contains('cash_out')) return Icons.output_outlined;
  return switch (entity) {
    'invoice' || 'sale' => Icons.receipt_long_outlined,
    'stock' || 'inventory' => Icons.inventory_2_outlined,
    _ => Icons.history,
  };
}
