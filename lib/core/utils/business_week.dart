import 'package:flutter/material.dart';

import 'business_period.dart';

/// @deprecated Use [BusinessPeriod] with API `period.from` / `period.to` instead.
/// Customer settlement cycle (Saturday) uses a different rule — see settlement docs.
class BusinessWeek {
  BusinessWeek._();

  @Deprecated('Use BusinessPeriod.rangeFromInfo with API period object')
  static DateTime weekStart(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final daysSinceSaturday = (local.weekday + 1) % 7;
    return local.subtract(Duration(days: daysSinceSaturday));
  }

  @Deprecated('Use BusinessPeriod.rangeFromInfo with API period object')
  static DateTime weekEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  @Deprecated('Use BusinessPeriod.rangeFromInfo with API period object')
  static DateTimeRange rangeFor(DateTime date) =>
      DateTimeRange(start: weekStart(date), end: weekEnd(date));

  static DateTime? parseInvoiceDate(String? raw) => BusinessPeriod.parseDate(raw);

  static bool isWithinWeek(String? createdAt, DateTimeRange week) =>
      BusinessPeriod.isWithin(createdAt, week.start, week.end);

  static String isoDate(DateTime d) => BusinessPeriod.isoDate(d);
}
