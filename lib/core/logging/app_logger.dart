import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Central app logging — all messages appear in debug console when [kDebugMode].
class AppLogger {
  AppLogger._();

  static final Logger _log = Logger('FrostParts');

  static void configure({Level level = Level.FINE}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      if (!kDebugMode) return;
      final buf = StringBuffer()
        ..write('[${record.loggerName}] ')
        ..write('${record.level.name}: ')
        ..write(record.message);
      if (record.error != null) {
        buf.write(' | error=${record.error}');
      }
      if (record.stackTrace != null) {
        buf.write('\n${record.stackTrace}');
      }
      debugPrint(buf.toString());
    });
  }

  /// User tapped a button or started a screen action.
  static void action(String name, [Map<String, Object?>? data]) {
    _log.fine(_format('ACTION $name', data));
  }

  /// Repository / cubit business step.
  static void repo(String name, [Map<String, Object?>? data]) {
    _log.fine(_format('REPO $name', data));
  }

  /// HTTP traffic summary (see also [ApiLoggingInterceptor]).
  static void api(String message, [Map<String, Object?>? data]) {
    _log.fine(_format('API $message', data));
  }

  static void info(String message, [Map<String, Object?>? data]) {
    _log.info(_format(message, data));
  }

  static void warning(String message, [Object? error, StackTrace? stack]) {
    _log.warning(_format(message, null), error, stack);
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    _log.severe(_format(message, null), error, stack);
  }

  static String? apiResponseMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg != null) return msg.toString();
    }
    return null;
  }

  static bool apiResponseMessageContains(DioException e, String needle) {
    final msg = apiResponseMessage(e)?.toLowerCase() ?? '';
    return msg.contains(needle.toLowerCase());
  }

  static String dioMessage(DioException e) {
    final parts = <String>[
      'HTTP ${e.response?.statusCode ?? '—'}',
      e.requestOptions.method,
      e.requestOptions.uri.toString(),
    ];
    final data = e.response?.data;
    if (data != null) {
      if (data is Map) {
        final msg = data['message'] ?? data['error'];
        if (msg != null) parts.add('$msg');
        final errors = data['errors'];
        if (errors is Map) {
          for (final entry in errors.entries) {
            parts.add('${entry.key}: ${entry.value}');
          }
        }
      } else {
        parts.add(data.toString());
      }
    } else {
      parts.add(e.message ?? e.type.name);
    }
    return parts.join(' · ');
  }

  static String _format(String prefix, Map<String, Object?>? data) {
    if (data == null || data.isEmpty) return prefix;
    final details = data.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    return '$prefix ($details)';
  }
}
