import 'package:flutter/material.dart';

import '../../data/models/dashboard_period_info.dart';

/// Week/month boundaries from API `period.from` / `period.to` — do not compute in Dart.
///
/// Business week (API): Monday 09:00 → Saturday 23:59:59.
/// Sunday shows the completed week; Monday before 09:00 is still the previous week.
class BusinessPeriod {
  BusinessPeriod._();

  static DateTimeRange? rangeFromInfo(DashboardPeriodInfo? info) {
    if (info?.from == null || info?.to == null) return null;
    return DateTimeRange(
      start: info!.from!.toLocal(),
      end: info.to!.toLocal(),
    );
  }

  static DateTime? parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  static bool isWithin(String? createdAt, DateTime from, DateTime to) {
    final dt = parseDate(createdAt);
    if (dt == null) return false;
    return !dt.isBefore(from) && !dt.isAfter(to);
  }

  static String isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
