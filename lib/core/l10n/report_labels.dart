import 'package:flutter/widgets.dart';

import 'api_labels.dart';
import 'l10n_extension.dart';

/// Short explanation shown at the top of each report screen.
String reportDescription(BuildContext context, ReportKind kind) {
  final l = context.l10n;
  return switch (kind) {
    ReportKind.sales => l.reportDescSales,
    ReportKind.inventory => l.reportDescInventory,
    ReportKind.customers => l.reportDescCustomers,
    ReportKind.suppliers => l.reportDescSuppliers,
    ReportKind.returns => l.reportDescReturns,
  };
}

/// Localized column title for report tables.
String reportColumnLabel(BuildContext context, String key) {
  final l = context.l10n;
  return switch (key) {
    'invoice_number' => l.colInvoiceNumber,
    'customer_name' => l.colCustomerName,
    'branch_name' => l.colBranchName,
    'payment_type' => l.colPaymentType,
    'total' => l.colTotal,
    'subtotal' => l.colSubtotal,
    'discount' => l.colDiscount,
    'created_at' => l.colDate,
    'name' => l.name,
    'code' => l.code,
    'quantity' => l.quantity,
    'value_cost' => l.colValueCost,
    'value_sell' => l.colValueSell,
    'outstanding_balance' => l.colOutstanding,
    'oldest_invoice_at' => l.colOldestInvoice,
    'total_debt' => l.colTotalDebt,
    'updated_at' => l.colUpdatedAt,
    'reason' => l.reason,
    'count' => l.colCount,
    _ => key,
  };
}

/// Formats a cell value for display (money, dates, nested objects skipped).
String formatReportCell(BuildContext context, String columnKey, dynamic value) {
  if (value == null) return '—';
  if (value is Map || value is List) return '—';
  if (columnKey == 'payment_type') {
    return localizePaymentType(context, value.toString());
  }
  if (columnKey == 'total' ||
      columnKey == 'subtotal' ||
      columnKey == 'discount' ||
      columnKey == 'value_cost' ||
      columnKey == 'value_sell' ||
      columnKey == 'outstanding_balance' ||
      columnKey == 'total_debt' ||
      columnKey == 'total_value') {
    final n = value is num ? value : num.tryParse('$value');
    if (n != null) return formatMoney(context, n);
  }
  if (columnKey.endsWith('_at') && value is String) {
    final s = value;
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
  return '$value';
}

/// Turns API rows into flat maps with user-facing column keys.
List<Map<String, dynamic>> flattenReportRows(
  BuildContext context,
  ReportKind kind,
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) => _flattenRow(context, kind, row)).toList();
}

Map<String, dynamic> _flattenRow(
  BuildContext context,
  ReportKind kind,
  Map<String, dynamic> row,
) {
  switch (kind) {
    case ReportKind.sales:
      final customer = row['customer'];
      final branch = row['branch'];
      return {
        'invoice_number': row['invoice_number'] ?? row['id'],
        'created_at': row['created_at'],
        'customer_name': customer is Map ? customer['name'] : null,
        'branch_name': branch is Map ? branch['name'] : null,
        'payment_type': row['payment_type'],
        'total': row['total'],
      };
    case ReportKind.inventory:
      return {
        'code': row['code'],
        'name': row['name'],
        'quantity': row['quantity'],
        'value_cost': row['value_cost'],
        'value_sell': row['value_sell'],
      };
    case ReportKind.customers:
      return {
        'name': row['name'],
        'outstanding_balance': row['outstanding_balance'],
        'oldest_invoice_at': row['oldest_invoice_at'],
      };
    case ReportKind.suppliers:
      return {
        'name': row['name'],
        'total_debt': row['total_debt'],
        'updated_at': row['updated_at'],
      };
    case ReportKind.returns:
      return row;
  }
}

enum ReportKind { sales, inventory, customers, suppliers, returns }
