import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class ReturnRepository {
  ReturnRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final r = await _dio.get<dynamic>('/returns');
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> get(String id) async {
    final r = await _dio.get<dynamic>('/returns/$id');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/returns', data: body);
    return parseObject(r.data);
  }

  Future<void> approve(String id, {String resolution = 'restock'}) async {
    await _dio.patch('/returns/$id/approve', data: {'resolution': resolution});
  }

  Future<void> reject(String id, {required String reason}) async {
    await _dio.patch('/returns/$id/reject', data: {'reason': reason});
  }
}
