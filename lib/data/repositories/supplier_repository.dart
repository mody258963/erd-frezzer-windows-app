import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../../core/utils/balance_parse.dart';
import '../models/linked_balance_model.dart';
import '../models/supplier_model.dart';

class SupplierRepository {
  SupplierRepository(this._dio);
  final Dio _dio;

  Future<List<SupplierModel>> list({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/suppliers',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, SupplierModel.fromJson);
  }

  Future<SupplierModel> get(String id) async {
    final r = await _dio.get<dynamic>('/suppliers/$id');
    return SupplierModel.fromJson(parseObject(r.data));
  }

  Future<double> debt(String id) async {
    final r = await _dio.get<dynamic>('/suppliers/$id/debt');
    return parseOutstandingBalance(parseObject(r.data));
  }

  Future<LinkedBalanceModel> linkedBalance(String id) async {
    final r = await _dio.get<dynamic>('/suppliers/$id/linked-balance');
    return LinkedBalanceModel.fromJson(parseObject(r.data));
  }

  Future<SupplierModel> create(
    Map<String, dynamic> body, {
    String? branchId,
  }) async {
    final bid = branchId?.trim();
    final payload = {
      ...body,
      if (bid != null && bid.isNotEmpty) 'branch_id': bid,
    };
    final r = await _dio.post<dynamic>(
      '/suppliers',
      queryParameters:
          bid != null && bid.isNotEmpty ? {'branch_id': bid} : null,
      data: payload,
    );
    return SupplierModel.fromJson(parseObject(r.data));
  }

  Future<SupplierModel> update(String id, Map<String, dynamic> body) async {
    final r = await _dio.put<dynamic>('/suppliers/$id', data: body);
    return SupplierModel.fromJson(parseObject(r.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete('/suppliers/$id');
  }
}
