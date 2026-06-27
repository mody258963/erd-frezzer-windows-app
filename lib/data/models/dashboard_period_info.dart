import '../../core/dashboard/dashboard_period.dart';

/// `period` object returned by filtered dashboard endpoints.
class DashboardPeriodInfo {
  const DashboardPeriodInfo({
    required this.key,
    this.from,
    this.to,
    this.anchorDate,
  });

  final DashboardPeriod key;
  final DateTime? from;
  final DateTime? to;
  final String? anchorDate;

  factory DashboardPeriodInfo.fromJson(dynamic json) {
    if (json is! Map) return const DashboardPeriodInfo(key: DashboardPeriod.week);
    final map = Map<String, dynamic>.from(json);
    return DashboardPeriodInfo(
      key: DashboardPeriod.parse(map['key'] as String?),
      from: _parseDateTime(map['from']),
      to: _parseDateTime(map['to']),
      anchorDate: map['anchor_date'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
