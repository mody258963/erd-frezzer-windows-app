import 'package:dio/dio.dart';

import '../../di/injection.dart';
import '../auth/auth_cubit.dart';
import '../branch/branch_filter_cubit.dart';

/// Injects active `branch_id` on authenticated API calls (GET and write methods).
///
/// Admin with no filter → no branch (aggregated reads). Admin with filter or any
/// non-admin user → `selectedBranchId` or `user.branch_id`.
class BranchFilterInterceptor extends Interceptor {
  static const _excludedPrefixes = [
    '/auth/',
    '/part-categories',
    '/part-units',
  ];

  static bool _isExcludedPath(String path) {
    if (path == '/branches' || path.startsWith('/branches/')) {
      return true;
    }
    return false;
  }

  String? _resolveBranchId() {
    if (!getIt.isRegistered<AuthCubit>() ||
        !getIt.isRegistered<BranchFilterCubit>()) {
      return null;
    }
    final user = getIt<AuthCubit>().state.user;
    if (user == null) return null;
    return getIt<BranchFilterCubit>().apiBranchId(user);
  }

  void _applyBranch(RequestOptions options, String branchId) {
    final params = Map<String, dynamic>.from(options.queryParameters);
    params.putIfAbsent('branch_id', () => branchId);
    options.queryParameters = params;

    options.headers.putIfAbsent('X-Branch-Id', () => branchId);

    final method = options.method.toUpperCase();
    if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
      final data = options.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        map.putIfAbsent('branch_id', () => branchId);
        options.data = map;
      }
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    for (final prefix in _excludedPrefixes) {
      if (path == prefix || path.startsWith(prefix)) {
        handler.next(options);
        return;
      }
    }
    if (_isExcludedPath(path)) {
      handler.next(options);
      return;
    }

    final branchId = _resolveBranchId();
    if (branchId != null && branchId.isNotEmpty) {
      _applyBranch(options, branchId);
    }

    handler.next(options);
  }
}
