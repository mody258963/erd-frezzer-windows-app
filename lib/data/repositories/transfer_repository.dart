import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class TransferRepository {
  TransferRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final r = await _dio.get<dynamic>('/transfers');
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> get(String id) async {
    final r = await _dio.get<dynamic>('/transfers/$id');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/transfers', data: body);
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) async {
    final r = await _dio.patch<dynamic>('/transfers/$id', data: body);
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> complete(
    String id, {
    String valuation = 'cost',
    bool recordBranchCharge = true,
  }) async {
    final r = await _dio.patch<dynamic>(
      '/transfers/$id/complete',
      data: {
        'valuation': valuation,
        'record_branch_charge': recordBranchCharge,
      },
    );
    return parseObject(r.data);
  }

  Future<void> cancel(String id) async {
    await _dio.patch('/transfers/$id/cancel');
  }
}
