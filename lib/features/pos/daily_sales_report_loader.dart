import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/dashboard/dashboard_period.dart';
import '../../core/printer/models/daily_sales_report.dart';
import '../../core/utils/payment_type.dart';
import '../../data/local/app_database.dart';
import '../../data/models/dashboard_cash_collections.dart';
import '../../data/models/dashboard_cash_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/supplier_installment_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/installment_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/settlement_repository.dart';

Future<DailySalesReport> loadDailySalesReport({
  required InvoiceRepository invoiceRepository,
  required AppDatabase database,
  required ConnectivityCubit connectivity,
  required String branchId,
  String? branchName,
  bool cashOnly = false,
}) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final today = _isoDate(now);
  final lines = <DailySalesReportLine>[];
  final seenServerIds = <String>{};

  // Always try the server — connectivity health can be false while invoices API works.
  try {
    final serverInvoices = await _fetchTodayServerInvoices(
      invoiceRepository: invoiceRepository,
      branchId: branchId,
      startOfDay: startOfDay,
      endOfDay: endOfDay,
      cashOnly: cashOnly,
    );
    for (final inv in serverInvoices) {
      seenServerIds.add(inv.id);
      final line = _lineFromInvoice(inv);
      if (cashOnly && !line.isCash) continue;
      lines.add(line);
    }
  } catch (_) {
    // Fall through to pending local sales below.
  }

  final pending = await database.pendingFifo();
  for (final pendingInvoice in pending) {
    if (!_matchesBranch(pendingInvoice.branchId, branchId)) continue;
    if (pendingInvoice.createdAt.isBefore(startOfDay) ||
        !pendingInvoice.createdAt.isBefore(endOfDay)) {
      continue;
    }
    final serverId = pendingInvoice.serverInvoiceId;
    if (serverId != null &&
        serverId.isNotEmpty &&
        seenServerIds.contains(serverId)) {
      continue;
    }
    final customerName =
        await database.getCustomerName(pendingInvoice.customerId) ??
            pendingInvoice.customerId;
    final line = DailySalesReportLine(
      invoiceNumber: pendingInvoice.localId.length > 8
          ? pendingInvoice.localId.substring(0, 8)
          : pendingInvoice.localId,
      time: _formatTime(pendingInvoice.createdAt),
      customerName: customerName,
      paymentType: pendingInvoice.paymentType,
      total: pendingInvoice.total,
      discount: pendingInvoice.discount,
      pending: serverId == null || serverId.isEmpty,
    );
    if (cashOnly && !line.isCash) continue;
    lines.add(line);
  }

  lines.sort((a, b) => a.time.compareTo(b.time));

  var cashTotal = 0.0;
  var creditTotal = 0.0;
  var discountTotal = 0.0;
  for (final line in lines) {
    discountTotal += line.discount;
    if (line.isCash) {
      cashTotal += line.total;
    } else {
      creditTotal += line.total;
    }
  }

  return DailySalesReport(
    date: today,
    branchName: branchName,
    lines: lines,
    invoiceCount: lines.length,
    cashTotal: cashTotal,
    creditTotal: cashOnly ? 0 : creditTotal,
    discountTotal: discountTotal,
    grandTotal: cashOnly ? cashTotal : (cashTotal + creditTotal),
  );
}

/// Hybrid drawer report: cash sales lines + dashboard cash totals.
Future<DailySalesReport> loadDailyDrawerReport({
  required InvoiceRepository invoiceRepository,
  required AppDatabase database,
  required ConnectivityCubit connectivity,
  required DashboardRepository dashboardRepository,
  required SettlementRepository settlementRepository,
  required InstallmentRepository installmentRepository,
  required String branchId,
  String? branchName,
}) async {
  final base = await loadDailySalesReport(
    invoiceRepository: invoiceRepository,
    database: database,
    connectivity: connectivity,
    branchId: branchId,
    branchName: branchName,
    cashOnly: true,
  );

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final today = _isoDate(now);

  final collections = <DailyDrawerLine>[];
  var collectionsDetailUnavailable = false;
  var collectionsFromApi = false;

  Map<String, dynamic> cashJson = const {};
  try {
    cashJson = await dashboardRepository.cash(
      branchId: branchId.isNotEmpty ? branchId : null,
      period: DashboardPeriod.day,
      anchorDate: now,
    );
  } catch (_) {}

  var apiRows = DashboardCashCollectionsParser.rowsFromCashResponse(cashJson);
  if (apiRows.isEmpty) {
    try {
      apiRows = await dashboardRepository.customerCollections(
        branchId: branchId.isNotEmpty ? branchId : null,
        period: DashboardPeriod.day,
        anchorDate: now,
      );
    } catch (_) {}
  }

  if (apiRows.isNotEmpty) {
    var lines = DashboardCashCollectionsParser.toDrawerLines(
      apiRows,
      startOfDay: startOfDay,
      endOfDay: endOfDay,
    );
    if (lines.isEmpty) {
      lines = DashboardCashCollectionsParser.toDrawerLines(apiRows);
    }
    collections.addAll(lines);
    collectionsFromApi = collections.isNotEmpty;
  }

  final cashApiReachable = cashJson.isNotEmpty;

  if (!collectionsFromApi) {
    try {
      final settlements = await settlementRepository.list();
      for (final s in settlements) {
        if (!_isOnLocalDay(
          '${s['created_at'] ?? s['settlement_date'] ?? ''}',
          startOfDay,
          endOfDay,
        )) {
          continue;
        }
        final method = '${s['payment_method'] ?? 'cash'}'.toLowerCase();
        if (!isCashPaymentType(method)) continue;
        final amount =
            ((s['amount'] ?? s['total_amount']) as num?)?.toDouble() ?? 0;
        if (amount <= 0) continue;
        final customer = s['customer'];
        final name = customer is Map
            ? '${customer['name'] ?? s['customer_id'] ?? '—'}'
            : '${s['customer_id'] ?? '—'}';
        collections.add(DailyDrawerLine(label: name, amount: amount));
      }
      if (collections.isNotEmpty) collectionsFromApi = true;
    } catch (_) {
      if (apiRows.isEmpty) collectionsDetailUnavailable = true;
    }
  }

  final outflows = <DailyDrawerLine>[];
  try {
    final installments = await installmentRepository.list();
    for (final inst in installments) {
      if (!inst.isPaid) continue;
      final paidAmount = inst.amountPaid > 0 ? inst.amountPaid : inst.amount;
      if (paidAmount <= 0) continue;
      if (!_installmentPaidToday(inst, startOfDay, endOfDay)) continue;
      final label = inst.supplierName ?? 'مورد';
      outflows.add(DailyDrawerLine(label: label, amount: paidAmount));
    }
  } catch (_) {}

  final cash = DashboardCash.fromResponses(summary: cashJson, cashEndpoint: cashJson);
  final cashInTotal = cash.periodCashInRealized;
  final cashOutTotal = cash.periodCashOutRealized;
  final drawerTotal = cash.periodNetCashFlowRealized != 0
      ? cash.periodNetCashFlowRealized
      : base.cashTotal + collections.fold(0.0, (s, c) => s + c.amount) -
          outflows.fold(0.0, (s, o) => s + o.amount);

  if (collections.isEmpty &&
      cashInTotal > base.cashTotal + 0.01 &&
      !collectionsFromApi) {
    if (!cashApiReachable) {
      collectionsDetailUnavailable = true;
    } else {
      final implied = cashInTotal - base.cashTotal;
      if (implied > 0.01) {
        collections.add(
          DailyDrawerLine(
            label: 'إجمالي التحصيلات',
            amount: implied,
          ),
        );
      }
    }
  }

  if (outflows.isEmpty && cashOutTotal > 0) {
    outflows.add(
      DailyDrawerLine(
        label: 'مدفوعات الموردين والمصاريف النقدية',
        amount: cashOutTotal,
      ),
    );
  } else if (outflows.isNotEmpty) {
    final listed = outflows.fold(0.0, (s, o) => s + o.amount);
    if (cashOutTotal > listed + 0.01) {
      outflows.add(
        DailyDrawerLine(
          label: 'مصاريف أخرى',
          amount: cashOutTotal - listed,
        ),
      );
    }
  }

  return DailySalesReport(
    date: today,
    branchName: branchName,
    lines: base.lines,
    invoiceCount: base.invoiceCount,
    cashTotal: base.cashTotal,
    creditTotal: base.creditTotal,
    discountTotal: base.discountTotal,
    grandTotal: base.grandTotal,
    cashSalesTotal: base.cashTotal,
    collections: collections,
    outflows: outflows,
    cashInTotal: cashInTotal,
    cashOutTotal: cashOutTotal,
    drawerTotal: drawerTotal,
    collectionsDetailUnavailable: collectionsDetailUnavailable,
  );
}

bool _isOnLocalDay(String raw, DateTime startOfDay, DateTime endOfDay) {
  if (raw.isEmpty) return false;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    final local = parsed.toLocal();
    return !local.isBefore(startOfDay) && local.isBefore(endOfDay);
  }
  if (raw.length >= 10) {
    return raw.substring(0, 10) == _isoDate(startOfDay);
  }
  return false;
}

bool _installmentPaidToday(
  SupplierInstallmentModel inst,
  DateTime startOfDay,
  DateTime endOfDay,
) {
  if (inst.dueDate != null && _isOnLocalDay(inst.dueDate!, startOfDay, endOfDay)) {
    return true;
  }
  return false;
}

Future<List<InvoiceModel>> _fetchTodayServerInvoices({
  required InvoiceRepository invoiceRepository,
  required String branchId,
  required DateTime startOfDay,
  required DateTime endOfDay,
  bool cashOnly = false,
}) async {
  final collected = <InvoiceModel>[];
  final seen = <String>{};
  final paymentFilter = cashOnly ? 'cash' : null;

  void addInvoices(Iterable<InvoiceModel> invoices) {
    for (final inv in invoices) {
      if (seen.contains(inv.id)) continue;
      if (inv.isCancelled) continue;
      if (!_matchesBranch(inv.branchId, branchId)) continue;
      if (!_isInvoiceOnLocalDay(inv.createdAt, startOfDay, endOfDay)) continue;
      if (cashOnly && !isCashPaymentType(inv.paymentType)) continue;
      seen.add(inv.id);
      collected.add(inv);
    }
  }

  Future<void> fetchAndAdd({
    String? from,
    String? to,
    String? queryBranchId,
    bool requireBranch = true,
  }) async {
    final invoices = await invoiceRepository.list(
      from: from,
      to: to,
      branchId: requireBranch ? queryBranchId : null,
      paymentType: paymentFilter,
      perPage: 100,
    );
    addInvoices(invoices);
  }

  final today = _isoDate(startOfDay);
  final tomorrow = _isoDate(endOfDay);

  // Primary: today window (API may treat `to` as exclusive).
  try {
    await fetchAndAdd(from: today, to: tomorrow, queryBranchId: branchId);
    if (collected.isNotEmpty) return collected;
  } catch (_) {}

  // Wider window for timezone skew.
  try {
    final from = _isoDate(startOfDay.subtract(const Duration(days: 1)));
    final to = _isoDate(endOfDay.add(const Duration(days: 1)));
    await fetchAndAdd(from: from, to: to, queryBranchId: branchId);
    if (collected.isNotEmpty) return collected;
  } catch (_) {}

  // Recent for branch, filter locally to today.
  try {
    await fetchAndAdd(queryBranchId: branchId);
    if (collected.isNotEmpty) return collected;
  } catch (_) {}

  // Last resort: today's invoices without branch filter (branch id mismatch on API).
  try {
    await fetchAndAdd(
      from: today,
      to: tomorrow,
      requireBranch: false,
    );
    if (collected.isNotEmpty) return collected;
  } catch (_) {}

  try {
    await fetchAndAdd(requireBranch: false);
  } catch (_) {}

  return collected;
}

bool _matchesBranch(String invoiceBranchId, String selectedBranchId) {
  final selected = selectedBranchId.trim();
  if (selected.isEmpty) return true;
  return invoiceBranchId.trim() == selected;
}

bool _isInvoiceOnLocalDay(
  String? createdAt,
  DateTime startOfDay,
  DateTime endOfDay,
) {
  if (createdAt == null || createdAt.isEmpty) {
    return true;
  }

  final parsed = DateTime.tryParse(createdAt);
  if (parsed != null) {
    final local = parsed.toLocal();
    return !local.isBefore(startOfDay) && local.isBefore(endOfDay);
  }

  if (createdAt.length >= 10) {
    final dateOnly = createdAt.substring(0, 10);
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateOnly)) {
      return dateOnly == _isoDate(startOfDay);
    }
  }

  return false;
}

DailySalesReportLine _lineFromInvoice(InvoiceModel inv) {
  return DailySalesReportLine(
    invoiceNumber: inv.displayNumber,
    time: _formatCreatedAt(inv.createdAt),
    customerName: inv.customerName ?? inv.customerId,
    paymentType: inv.paymentType,
    total: inv.total,
    discount: inv.discount,
  );
}

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatCreatedAt(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return '';
  final parsed = DateTime.tryParse(createdAt);
  if (parsed != null) {
    return _formatTime(parsed.toLocal());
  }
  if (createdAt.length >= 16 && createdAt.contains('T')) {
    return createdAt.substring(11, 16);
  }
  if (createdAt.length >= 16 && createdAt.contains(' ')) {
    return createdAt.substring(11, 16);
  }
  return createdAt;
}
