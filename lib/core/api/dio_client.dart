import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../settings/settings_service.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient(this._settings, this._secureStorage);

  final SettingsService _settings;
  final SecureStorage _secureStorage;
  Dio? _dio;

  Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  void reset() {
    _dio = null;
  }

  Dio _createDio() {
    final base = _settings.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final client = Dio(
      BaseOptions(
        baseUrl: '$base${AppConstants.apiVersionPath}',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    client.interceptors.add(
      AuthInterceptor(secureStorage: _secureStorage),
    );
    return client;
  }
}
