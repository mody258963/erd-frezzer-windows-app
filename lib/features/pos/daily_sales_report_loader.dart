import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/printer/models/daily_sales_report.dart';
import '../../data/local/app_database.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';

Future<DailySalesReport> loadDailySalesReport({
  required InvoiceRepository invoiceRepository,
  required AppDatabase database,
  required ConnectivityCubit connectivity,
  required String branchId,
  String? branchName,
}) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final today = _isoDate(now);
  final lines = <DailySalesReportLine>[];
  final seenServerIds = <String>{};

  if (connectivity.state.isOnline) {
    final serverInvoices = await _fetchTodayServerInvoices(
      invoiceRepository: invoiceRepository,
      branchId: branchId,
      startOfDay: startOfDay,
      endOfDay: endOfDay,
    );
    for (final inv in serverInvoices) {
      seenServerIds.add(inv.id);
      lines.add(_lineFromInvoice(inv));
    }
  }

  final pending = await database.pendingFifo();
  for (final pendingInvoice in pending) {
    if (pendingInvoice.branchId != branchId) continue;
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
    lines.add(
      DailySalesReportLine(
        invoiceNumber: pendingInvoice.localId.length > 8
            ? pendingInvoice.localId.substring(0, 8)
            : pendingInvoice.localId,
        time: _formatTime(pendingInvoice.createdAt),
        customerName: customerName,
        paymentType: pendingInvoice.paymentType,
        total: pendingInvoice.total,
        discount: pendingInvoice.discount,
        pending: serverId == null || serverId.isEmpty,
      ),
    );
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
    creditTotal: creditTotal,
    discountTotal: discountTotal,
    grandTotal: cashTotal + creditTotal,
  );
}

Future<List<InvoiceModel>> _fetchTodayServerInvoices({
  required InvoiceRepository invoiceRepository,
  required String branchId,
  required DateTime startOfDay,
  required DateTime endOfDay,
}) async {
  final collected = <InvoiceModel>[];
  final seen = <String>{};

  void addInvoices(Iterable<InvoiceModel> invoices) {
    for (final inv in invoices) {
      if (seen.contains(inv.id)) continue;
      if (inv.isCancelled) continue;
      if (inv.branchId != branchId) continue;
      if (!_isInvoiceOnLocalDay(inv.createdAt, startOfDay, endOfDay)) continue;
      seen.add(inv.id);
      collected.add(inv);
    }
  }

  // Primary: explicit today window (API may treat `to` as exclusive — use tomorrow).
  try {
    final today = _isoDate(startOfDay);
    final tomorrow = _isoDate(endOfDay);
    final primary = await invoiceRepository.list(
      from: today,
      to: tomorrow,
      branchId: branchId,
      perPage: 200,
    );
    addInvoices(primary);
    if (collected.isNotEmpty) return collected;
  } catch (_) {}

  // Wider window for timezone skew between device and server.
  try {
    final from = _isoDate(startOfDay.subtract(const Duration(days: 1)));
    final to = _isoDate(endOfDay.add(const Duration(days: 1)));
    final wide = await invoiceRepository.list(
      from: from,
      to: to,
      branchId: branchId,
      perPage: 200,
    );
    addInvoices(wide);
    if (collected.isNotEmpty) return collected;
  } catch (_) {}

  // Fallback: recent invoices for this branch, filter to local calendar day.
  try {
    final recent = await invoiceRepository.list(
      branchId: branchId,
      perPage: 200,
    );
    addInvoices(recent);
  } catch (_) {}

  return collected;
}

bool _isInvoiceOnLocalDay(
  String? createdAt,
  DateTime startOfDay,
  DateTime endOfDay,
) {
  if (createdAt == null || createdAt.isEmpty) {
    // Include when API already scoped by date but omitted timestamp.
    return true;
  }
  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return false;
  final local = parsed.toLocal();
  return !local.isBefore(startOfDay) && local.isBefore(endOfDay);
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
