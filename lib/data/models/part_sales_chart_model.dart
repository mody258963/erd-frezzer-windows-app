class PartSalesChartData {
  const PartSalesChartData({
    required this.year,
    required this.months,
    required this.series,
    required this.rankBy,
    required this.limit,
  });

  final int year;
  final List<String> months;
  final List<PartSalesChartSeries> series;
  final String rankBy;
  final int limit;

  factory PartSalesChartData.fromJson(Map<String, dynamic> json) =>
      PartSalesChartData(
        year: _int(json['year']) ?? DateTime.now().year,
        months: (json['months'] as List? ?? [])
            .map((e) => '$e')
            .toList(),
        series: (json['series'] as List? ?? [])
            .map(
              (e) => PartSalesChartSeries.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
        rankBy: '${json['rank_by'] ?? 'units'}',
        limit: _int(json['limit']) ?? 10,
      );

  bool get rankByRevenue => rankBy == 'revenue';
}

class PartSalesChartSeries {
  const PartSalesChartSeries({
    required this.partId,
    required this.code,
    required this.name,
    required this.totalUnitsSold,
    required this.totalRevenue,
    required this.byMonth,
  });

  final String partId;
  final String code;
  final String name;
  final int totalUnitsSold;
  final double totalRevenue;
  final List<PartSalesChartMonthPoint> byMonth;

  String get label =>
      code.isNotEmpty && name.isNotEmpty ? '$code — $name' : name;

  factory PartSalesChartSeries.fromJson(Map<String, dynamic> json) =>
      PartSalesChartSeries(
        partId: '${json['part_id'] ?? ''}',
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        totalUnitsSold: _int(json['total_units_sold']) ?? 0,
        totalRevenue: _double(json['total_revenue']),
        byMonth: (json['by_month'] as List? ?? [])
            .map(
              (e) => PartSalesChartMonthPoint.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );

  double valueAtMonthIndex(List<String> months, int index, bool byRevenue) {
    if (index < 0 || index >= months.length) return 0;
    final key = months[index];
    final point = byMonth.where((p) => p.month == key).firstOrNull;
    if (point == null) return 0;
    return byRevenue ? point.revenue : point.unitsSold.toDouble();
  }
}

class PartSalesChartMonthPoint {
  const PartSalesChartMonthPoint({
    required this.month,
    required this.unitsSold,
    required this.revenue,
  });

  final String month;
  final int unitsSold;
  final double revenue;

  factory PartSalesChartMonthPoint.fromJson(Map<String, dynamic> json) =>
      PartSalesChartMonthPoint(
        month: '${json['month'] ?? ''}',
        unitsSold: _int(json['units_sold']) ?? 0,
        revenue: _double(json['revenue']),
      );
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
