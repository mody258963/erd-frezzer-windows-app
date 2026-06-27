import 'package:erd_rezzer/core/utils/business_period.dart';
import 'package:erd_rezzer/data/models/dashboard_period_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessPeriod', () {
    test('isWithin respects API week boundaries (Mon 9 AM – Sat 23:59:59)', () {
      final from = DateTime.parse('2026-06-15T09:00:00');
      final to = DateTime.parse('2026-06-20T23:59:59');

      expect(
        BusinessPeriod.isWithin('2026-06-15T08:30:00', from, to),
        isFalse,
      );
      expect(
        BusinessPeriod.isWithin('2026-06-15T10:00:00', from, to),
        isTrue,
      );
      expect(
        BusinessPeriod.isWithin('2026-06-20T22:00:00', from, to),
        isTrue,
      );
      expect(
        BusinessPeriod.isWithin('2026-06-21T00:30:00', from, to),
        isFalse,
      );
    });

    test('rangeFromInfo parses dashboard period object', () {
      final info = DashboardPeriodInfo.fromJson({
        'key': 'week',
        'from': '2026-06-15T09:00:00+00:00',
        'to': '2026-06-20T23:59:59+00:00',
      });
      final range = BusinessPeriod.rangeFromInfo(info);
      expect(range, isNotNull);
      expect(range!.start, info.from!.toLocal());
      expect(range.end, info.to!.toLocal());
    });
  });
}
