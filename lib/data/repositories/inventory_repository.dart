import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/stock_model.dart';

class InventoryRepository {
  InventoryRepository(this._dio);
  final Dio _dio;

  Future<List<StockModel>> list({
    String? branchId,
    String? partId,
    int perPage = 100,
  }) async {
    final response = await _dio.get<dynamic>(
      '/inventory',
      queryParameters: {
        if (branchId != null) 'branch_id': branchId,
        if (partId != null) 'part_id': partId,
        'per_page': perPage,
      },
    );
    return parseList(response.data, StockModel.fromJson);
  }

  Future<List<StockModel>> byBranch(String branchId) async {
    final response = await _dio.get<dynamic>(
      '/inventory/$branchId',
      queryParameters: {'branch_id': branchId},
    );
    return parseList(response.data, StockModel.fromJson);
  }

  Future<List<Map<String, dynamic>>> lowStock({String? branchId}) async {
    final response = await _dio.get<dynamic>(
      '/inventory/low-stock',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(response.data, (j) => j);
  }

  Future<void> adjust(Map<String, dynamic> body) async {
    await _dio.post('/inventory/adjust', data: body);
  }
}
