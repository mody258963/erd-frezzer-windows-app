import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/capital_model.dart';

class CapitalRepository {
  CapitalRepository(this._dio);

  final Dio _dio;

  Future<CapitalSettings> get({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/settings/capital',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return CapitalSettings.fromJson(parseObject(r.data));
  }

  Future<CapitalSettings> update({
    required double capitalAmount,
    required String reason,
    String? notes,
    String? branchId,
  }) async {
    final r = await _dio.patch<dynamic>(
      '/settings/capital',
      data: {
        'capital_amount': capitalAmount,
        'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return CapitalSettings.fromJson(parseObject(r.data));
  }

  Future<List<Map<String, dynamic>>> adjustments({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/settings/capital/adjustments',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> cashOuts({
    int perPage = 25,
    String? branchId,
  }) async {
    final r = await _dio.get<dynamic>(
      '/settings/capital/cash-outs',
      queryParameters: {
        'per_page': perPage,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, (j) => j);
  }

  /// Owner withdrawal from realized profit — does not reduce capital.
  Future<CapitalSettings> cashOut({
    required double amount,
    String? reason,
    String? notes,
    String? branchId,
  }) async {
    final r = await _dio.post<dynamic>(
      '/settings/capital/cash-out',
      data: {
        'amount': amount,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return _capitalFromCashOutResponse(r.data);
  }

  CapitalSettings _capitalFromCashOutResponse(dynamic data) {
    final root = parseObject(data);
    final capital = root['capital'];
    if (capital is Map) {
      return CapitalSettings.fromJson(Map<String, dynamic>.from(capital));
    }
    return CapitalSettings.fromJson(root);
  }
}
