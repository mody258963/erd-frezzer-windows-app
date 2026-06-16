import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  static Map<String, dynamic> _branchQuery(String? branchId) => {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      };

  Future<Map<String, dynamic>> summary({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/summary',
      queryParameters: _branchQuery(branchId),
    );
    return parseObject(r.data);
  }

  Future<List<Map<String, dynamic>>> inventory({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/inventory',
      queryParameters: _branchQuery(branchId),
    );
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> receivables({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/receivables',
      queryParameters: _branchQuery(branchId),
    );
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> payables({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/payables',
      queryParameters: _branchQuery(branchId),
    );
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> sales({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/sales',
      queryParameters: _branchQuery(branchId),
    );
    return parseObject(r.data);
  }

  Future<List<Map<String, dynamic>>> activity({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/activity',
      queryParameters: _branchQuery(branchId),
    );
    return parseList(r.data, (j) => j);
  }

  /// Sales broken down by product (falls back to reports endpoint shape).
  Future<List<Map<String, dynamic>>> productSales({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/reports/sales',
      queryParameters: _branchQuery(branchId),
    );
    return parseList(r.data, (j) => j);
  }
}
