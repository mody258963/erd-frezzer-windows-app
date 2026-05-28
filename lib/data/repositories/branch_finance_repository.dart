import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class BranchFinanceRepository {
  BranchFinanceRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> balances() async {
    final r = await _dio.get<dynamic>('/branch-finance/balances');
    final data = r.data;
    if (data is Map && data['balances'] is List) {
      return (data['balances'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> entries({
    String? creditorBranchId,
    String? debtorBranchId,
    String? status,
    String? entryType,
    int perPage = 50,
  }) async {
    final r = await _dio.get<dynamic>(
      '/branch-finance/entries',
      queryParameters: {
        if (creditorBranchId != null && creditorBranchId.isNotEmpty)
          'creditor_branch_id': creditorBranchId,
        if (debtorBranchId != null && debtorBranchId.isNotEmpty)
          'debtor_branch_id': debtorBranchId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (entryType != null && entryType.isNotEmpty) 'entry_type': entryType,
        'per_page': perPage,
      },
    );
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> getEntry(String id) async {
    final r = await _dio.get<dynamic>('/branch-finance/entries/$id');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> createCharge(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/branch-finance/charges', data: body);
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/branch-finance/payments', data: body);
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> settle(String id) async {
    final r = await _dio.patch<dynamic>('/branch-finance/entries/$id/settle');
    return parseObject(r.data);
  }
}
