import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> summary() async {
    final r = await _dio.get<dynamic>('/dashboard/summary');
    return parseObject(r.data);
  }

  Future<List<Map<String, dynamic>>> inventory() async {
    final r = await _dio.get<dynamic>('/dashboard/inventory');
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> receivables() async {
    final r = await _dio.get<dynamic>('/dashboard/receivables');
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> payables() async {
    final r = await _dio.get<dynamic>('/dashboard/payables');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> sales() async {
    final r = await _dio.get<dynamic>('/dashboard/sales');
    return parseObject(r.data);
  }

  Future<List<Map<String, dynamic>>> activity() async {
    final r = await _dio.get<dynamic>('/dashboard/activity');
    return parseList(r.data, (j) => j);
  }

  /// Sales broken down by product (falls back to reports endpoint shape).
  Future<List<Map<String, dynamic>>> productSales() async {
    final r = await _dio.get<dynamic>('/reports/sales');
    return parseList(r.data, (j) => j);
  }
}
