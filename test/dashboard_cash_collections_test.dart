import 'package:erd_rezzer/core/printer/models/daily_sales_report.dart';
import 'package:erd_rezzer/data/models/dashboard_cash_collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardCashCollectionsParser', () {
    test('rowsFromCashResponse reads customer_collections', () {
      final rows = DashboardCashCollectionsParser.rowsFromCashResponse({
        'customer_collections': [
          {
            'customer_name': 'أحمد',
            'amount': 150,
            'payment_method': 'cash',
            'paid_at': '2026-06-22T10:00:00',
          },
        ],
      });

      expect(rows, hasLength(1));
      expect(rows.first['customer_name'], 'أحمد');
    });

    test('rowsFromCashResponse reads nested breakdown', () {
      final rows = DashboardCashCollectionsParser.rowsFromCashResponse({
        'cash_in_breakdown': {
          'customer_payments': [
            {'customer': {'name': 'سارة'}, 'amount': 80, 'payment_method': 'cash'},
          ],
        },
      });

      expect(rows, hasLength(1));
    });

    test('rowsFromCashResponse reads nested items array', () {
      final rows = DashboardCashCollectionsParser.rowsFromCashResponse({
        'customer_collections': {
          'items': [
            {
              'customer_name': 'محمد',
              'amount': 200,
              'payment_method': 'cash',
            },
          ],
        },
      });

      expect(rows, hasLength(1));
      expect(rows.first['customer_name'], 'محمد');
    });

    test('toDrawerLines filters offset and non-today rows', () {
      final start = DateTime(2026, 6, 22);
      final end = start.add(const Duration(days: 1));
      final lines = DashboardCashCollectionsParser.toDrawerLines(
        [
          {
            'customer_name': 'نقدي',
            'amount': 70,
            'payment_method': 'cash',
            'paid_at': '2026-06-22T14:00:00',
          },
          {
            'customer_name': 'مقاصة',
            'amount': 50,
            'payment_method': 'offset',
            'paid_at': '2026-06-22T14:00:00',
          },
          {
            'customer_name': 'أمس',
            'amount': 40,
            'payment_method': 'cash',
            'paid_at': '2026-06-21T14:00:00',
          },
        ],
        startOfDay: start,
        endOfDay: end,
      );

      expect(lines, hasLength(1));
      expect(lines.first.label, 'نقدي');
      expect(lines.first.amount, 70);
    });
  });
}
