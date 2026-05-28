import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/branch_model.dart';

class BranchRepository {
  BranchRepository(this._dio);
  final Dio _dio;

  Future<List<BranchModel>> list({int perPage = 100}) async {
    final response = await _dio.get<dynamic>(
      '/branches',
      queryParameters: {'per_page': perPage},
    );
    return parseList(response.data, BranchModel.fromJson);
  }

  Future<BranchModel> get(String id) async {
    final response = await _dio.get<dynamic>('/branches/$id');
    return BranchModel.fromJson(parseObject(response.data));
  }

  Future<BranchModel> create(Map<String, dynamic> body) async {
    final response = await _dio.post<dynamic>('/branches', data: body);
    return BranchModel.fromJson(parseObject(response.data));
  }

  Future<BranchModel> update(String id, Map<String, dynamic> body) async {
    final response = await _dio.put<dynamic>('/branches/$id', data: body);
    return BranchModel.fromJson(parseObject(response.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete('/branches/$id');
  }
}
