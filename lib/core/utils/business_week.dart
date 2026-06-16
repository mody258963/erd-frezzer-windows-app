import 'package:flutter/material.dart';

/// Business week runs Saturday → today (credit settlements are on Saturdays).
class BusinessWeek {
  BusinessWeek._();

  static DateTime weekStart(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final daysSinceSaturday = (local.weekday + 1) % 7;
    return local.subtract(Duration(days: daysSinceSaturday));
  }

  static DateTime weekEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static DateTimeRange rangeFor(DateTime date) =>
      DateTimeRange(start: weekStart(date), end: weekEnd(date));

  static DateTime? parseInvoiceDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  static bool isWithinWeek(String? createdAt, DateTimeRange week) {
    final dt = parseInvoiceDate(createdAt);
    if (dt == null) return false;
    return !dt.isBefore(week.start) && !dt.isAfter(week.end);
  }

  static String isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
