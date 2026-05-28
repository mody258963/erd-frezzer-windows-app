import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class SupplierRepository {
  SupplierRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final r = await _dio.get<dynamic>('/suppliers');
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> get(String id) async {
    final r = await _dio.get<dynamic>('/suppliers/$id');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> debt(String id) async {
    final r = await _dio.get<dynamic>('/suppliers/$id/debt');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/suppliers', data: body);
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) async {
    final r = await _dio.put<dynamic>('/suppliers/$id', data: body);
    return parseObject(r.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/suppliers/$id');
  }
}
