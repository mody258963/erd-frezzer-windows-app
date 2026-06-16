import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  Future<List<UserModel>> list({String? branchId, String? role}) async {
    final r = await _dio.get<dynamic>(
      '/users',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
        if (role != null && role.isNotEmpty) 'role': role,
      },
    );
    return parseList(r.data, UserModel.fromJson);
  }

  Future<UserModel> create(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/users', data: body);
    return UserModel.fromJson(parseObject(r.data));
  }

  Future<UserModel> update(String id, Map<String, dynamic> body) async {
    final r = await _dio.patch<dynamic>('/users/$id', data: body);
    return UserModel.fromJson(parseObject(r.data));
  }

  Future<void> deactivate(String id) async {
    await _dio.delete('/users/$id');
  }
}
