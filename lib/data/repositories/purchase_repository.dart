import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class PurchaseRepository {
  PurchaseRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final r = await _dio.get<dynamic>('/purchases');
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> get(String id) async {
    final r = await _dio.get<dynamic>('/purchases/$id');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/purchases', data: body);
    return parseObject(r.data);
  }

  Future<void> receive(String id) async {
    await _dio.patch('/purchases/$id/receive');
  }

  Future<void> cancel(String id) async {
    await _dio.patch('/purchases/$id/cancel');
  }
}
