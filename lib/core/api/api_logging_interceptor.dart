import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Logs every HTTP request/response in debug builds.
class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.api(
      '→ ${options.method} ${options.uri}',
      {
        if (options.data != null) 'body': options.data.toString(),
        if (options.queryParameters.isNotEmpty)
          'query': options.queryParameters.toString(),
      },
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.api(
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
      {
        if (response.data != null)
          'data': _truncate(response.data.toString()),
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      AppLogger.dioMessage(err),
      err,
      err.stackTrace,
    );
    handler.next(err);
  }

  String _truncate(String s, [int max = 400]) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…';
  }
}
