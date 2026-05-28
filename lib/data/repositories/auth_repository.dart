import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._dio, this._secureStorage);

  final Dio _dio;
  final SecureStorage _secureStorage;
  final _log = Logger('AuthRepository');

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    final token = data['token'] as String;
    await _secureStorage.writeToken(token);
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    _logSession('login', userJson, user);
    await _secureStorage.writeCachedUser(user.toJsonString());
    return user;
  }

  Future<UserModel> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    final json = response.data!;
    final data = json.containsKey('data')
        ? json['data'] as Map<String, dynamic>
        : json;
    final user = UserModel.fromJson(data);
    _logSession('me', data, user);
    await _secureStorage.writeCachedUser(user.toJsonString());
    return user;
  }

  void _logSession(String source, Map<String, dynamic> raw, UserModel user) {
    _log.info(
      '$source: userId=${user.id} role=${user.role.name} '
      'branchId=${user.branchId} branchName=${user.branchName} | '
      'raw branch_id=${raw['branch_id']} raw branch=${raw['branch']}',
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await clearSessionLocal();
  }

  Future<void> clearSessionLocal() async {
    await _secureStorage.deleteToken();
    await _secureStorage.deleteCachedUser();
  }

  Future<String?> getStoredToken() => _secureStorage.readToken();

  Future<UserModel?> getCachedUser() async {
    final raw = await _secureStorage.readCachedUser();
    return UserModel.fromJsonString(raw);
  }
}
