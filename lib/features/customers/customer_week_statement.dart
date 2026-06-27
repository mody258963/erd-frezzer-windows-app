import '../../core/utils/business_period.dart';
import '../../core/printer/models/customer_week_statement.dart';
import '../../data/models/dashboard_period_info.dart';
import '../../data/models/invoice_model.dart';

export '../../core/printer/models/customer_week_statement.dart';

/// Open (unsettled) invoices within the API business week (`period.from`–`period.to`).
List<InvoiceModel> openInvoicesThisWeek(
  List<InvoiceModel> invoices, {
  DashboardPeriodInfo? weekPeriod,
}) {
  final range = BusinessPeriod.rangeFromInfo(weekPeriod);
  if (range == null) return [];
  return invoices.where((inv) {
    if (inv.isSettled) return false;
    return BusinessPeriod.isWithin(inv.createdAt, range.start, range.end);
  }).toList();
}

/// Aggregate line items by part across invoices.
List<CustomerWeekStatementLine> aggregateWeekPurchaseLines(
  List<InvoiceModel> invoices,
) {
  final map = <String, CustomerWeekStatementLine>{};
  for (final inv in invoices) {
    for (final item in inv.items) {
      final key = item.partId;
      final name = item.partName ?? item.partCode ?? item.partId;
      final lineTotal =
          item.lineTotal ?? (item.unitPrice ?? 0) * item.quantity;
      final existing = map[key];
      if (existing != null) {
        map[key] = CustomerWeekStatementLine(
          partId: key,
          partName: name,
          partCode: item.partCode ?? existing.partCode,
          quantity: existing.quantity + item.quantity,
          lineTotal: existing.lineTotal + lineTotal,
        );
      } else {
        map[key] = CustomerWeekStatementLine(
          partId: key,
          partName: name,
          partCode: item.partCode,
          quantity: item.quantity,
          lineTotal: lineTotal,
        );
      }
    }
  }
  final lines = map.values.toList();
  lines.sort((a, b) => a.partName.compareTo(b.partName));
  return lines;
}

CustomerWeekStatement buildCustomerWeekStatement({
  required String customerName,
  String? customerPhone,
  required List<InvoiceModel> weekInvoices,
  DashboardPeriodInfo? weekPeriod,
  double? paymentsCollected,
}) {
  final range = BusinessPeriod.rangeFromInfo(weekPeriod);
  final weekStart = range != null
      ? BusinessPeriod.isoDate(range.start)
      : '—';
  final weekEnd =
      range != null ? BusinessPeriod.isoDate(range.end) : '—';
  final lines = aggregateWeekPurchaseLines(weekInvoices);
  final total = lines.fold(0.0, (sum, line) => sum + line.lineTotal);
  return CustomerWeekStatement(
    customerName: customerName,
    customerPhone: customerPhone,
    weekStart: weekStart,
    weekEnd: weekEnd,
    lines: lines,
    weekTotal: total,
    paymentsCollected: paymentsCollected,
  );
}

/// Sum cash payments recorded this week (from customer payment maps).
double sumWeekCashPayments(
  List<Map<String, dynamic>> payments, {
  DashboardPeriodInfo? weekPeriod,
}) {
  final range = BusinessPeriod.rangeFromInfo(weekPeriod);
  if (range == null) return 0;
  var total = 0.0;
  for (final p in payments) {
    final method = '${p['payment_method'] ?? 'cash'}'.toLowerCase();
    if (method != 'cash') continue;
    final raw = '${p['created_at'] ?? p['paid_at'] ?? ''}';
    final dt = BusinessPeriod.parseDate(raw);
    if (dt == null) continue;
    if (dt.isBefore(range.start) || dt.isAfter(range.end)) continue;
    total += (p['amount'] as num?)?.toDouble() ?? 0;
  }
  return total;
}
