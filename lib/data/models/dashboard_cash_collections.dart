import '../../core/printer/models/daily_sales_report.dart';
import '../../core/utils/payment_type.dart';

/// Parses customer collection rows from `GET /dashboard/cash` (and related endpoints).
class DashboardCashCollectionsParser {
  DashboardCashCollectionsParser._();

  static const _rowListKeys = [
    'customer_collections',
    'collections',
    'collection_details',
    'period_customer_collections',
    'customer_payments',
    'available_collections',
  ];

  static const _breakdownKeys = [
    'cash_in_breakdown',
    'breakdown',
    'period_breakdown',
  ];

  static const _nestedListKeys = [
    'customer_payments',
    'collections',
    'customer_collections',
    'available_collections',
  ];

  /// Extracts collection/payment rows from a dashboard cash JSON object.
  static List<Map<String, dynamic>> rowsFromCashResponse(
    Map<String, dynamic> json,
  ) {
    for (final key in _rowListKeys) {
      final parsed = _asMapList(json[key]);
      if (parsed.isNotEmpty) return parsed;
    }

    for (final key in _breakdownKeys) {
      final breakdown = json[key];
      if (breakdown is! Map) continue;
      final map = Map<String, dynamic>.from(breakdown);
      for (final nested in _nestedListKeys) {
        final parsed = _asMapList(map[nested]);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    return const [];
  }

  static List<DailyDrawerLine> toDrawerLines(
    List<Map<String, dynamic>> rows, {
    DateTime? startOfDay,
    DateTime? endOfDay,
  }) {
    final lines = <DailyDrawerLine>[];
    for (final row in rows) {
      final method = '${row['payment_method'] ?? row['method'] ?? 'cash'}'
          .toLowerCase();
      if (method == 'offset' || method == 'مقاصة') continue;
      if (!isCashPaymentType(method) &&
          method != 'bank_transfer' &&
          method != 'check' &&
          method != 'transfer') {
        continue;
      }

      final paidAt = row['paid_at'] ??
          row['created_at'] ??
          row['payment_date'] ??
          row['date'];
      if (startOfDay != null &&
          endOfDay != null &&
          paidAt != null &&
          !_isOnLocalDay('$paidAt', startOfDay, endOfDay)) {
        continue;
      }

      final amount = _num(
        row['amount'] ?? row['total_amount'] ?? row['total'] ?? row['value'],
      );
      if (amount <= 0) continue;

      final label = _customerLabel(row);
      lines.add(DailyDrawerLine(label: label, amount: amount));
    }
    return lines;
  }

  static String _customerLabel(Map<String, dynamic> row) {
    final customer = row['customer'];
    if (customer is Map) {
      final name = customer['name'] ?? customer['customer_name'];
      if (name != null && '$name'.trim().isNotEmpty) return '$name'.trim();
    }
    for (final key in [
      'customer_name',
      'name',
      'label',
      'description',
      'customer_id',
    ]) {
      final v = row[key];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    return 'عميل';
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in ['items', 'data', 'rows', 'lines', 'details']) {
        final nested = _asMapList(map[key]);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  static bool _isOnLocalDay(
    String raw,
    DateTime startOfDay,
    DateTime endOfDay,
  ) {
    if (raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final local = parsed.toLocal();
      return !local.isBefore(startOfDay) && local.isBefore(endOfDay);
    }
    if (raw.length >= 10) {
      final y = startOfDay.year.toString().padLeft(4, '0');
      final m = startOfDay.month.toString().padLeft(2, '0');
      final d = startOfDay.day.toString().padLeft(2, '0');
      return raw.substring(0, 10) == '$y-$m-$d';
    }
    return false;
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
