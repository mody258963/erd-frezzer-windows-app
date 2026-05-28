import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class SecureStorage {
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: AppConstants.tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: AppConstants.tokenKey);

  Future<String?> readCachedUser() =>
      _storage.read(key: AppConstants.cachedUserKey);

  Future<void> writeCachedUser(String json) =>
      _storage.write(key: AppConstants.cachedUserKey, value: json);

  Future<void> deleteCachedUser() =>
      _storage.delete(key: AppConstants.cachedUserKey);
}
