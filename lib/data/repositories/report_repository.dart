import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class ReportRepository {
  ReportRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> sales({
    String? from,
    String? to,
    String? branchId,
  }) async {
    final r = await _dio.get<dynamic>(
      '/reports/sales',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> inventory() async {
    final r = await _dio.get<dynamic>('/reports/inventory');
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> customers() async {
    final r = await _dio.get<dynamic>('/reports/customers');
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> suppliers() async {
    final r = await _dio.get<dynamic>('/reports/suppliers');
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> returns({
    String? from,
    String? to,
  }) async {
    final r = await _dio.get<dynamic>(
      '/reports/returns',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return parseObject(r.data);
  }

  /// `GET /reports/parts-sales-chart` — top parts by month for charts.
  Future<Map<String, dynamic>> partsSalesChart({
    int? year,
    int limit = 10,
    String rankBy = 'units',
    String? branchId,
  }) async {
    final r = await _dio.get<dynamic>(
      '/reports/parts-sales-chart',
      queryParameters: {
        if (year != null) 'year': year,
        'limit': limit.clamp(1, 50),
        'rank_by': rankBy,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseObject(r.data);
  }
}
