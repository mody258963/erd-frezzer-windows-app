/// Time window for dashboard KPIs (`day`, `week`, `month`).
enum DashboardPeriod {
  day,
  week,
  month;

  String get apiValue => name;

  static DashboardPeriod parse(String? value) {
    return DashboardPeriod.values.firstWhere(
      (p) => p.name == value,
      orElse: () => DashboardPeriod.week,
    );
  }
}

String formatDashboardDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

Map<String, dynamic> dashboardPeriodQuery({
  DashboardPeriod period = DashboardPeriod.week,
  DateTime? anchorDate,
  String? branchId,
}) {
  return {
    'period': period.apiValue,
    if (anchorDate != null) 'date': formatDashboardDate(anchorDate),
    if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
  };
}
