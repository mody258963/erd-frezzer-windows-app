import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../../core/logging/app_logger.dart';
import '../models/purchase_order_model.dart';

class PurchaseRepository {
  PurchaseRepository(this._dio);
  final Dio _dio;

  Future<List<PurchaseOrderModel>> list({String? branchId}) async {
    AppLogger.repo('purchase.list');
    final r = await _dio.get<dynamic>(
      '/purchases',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    final items = parseList(r.data, PurchaseOrderModel.fromJson);
    AppLogger.repo('purchase.list.ok', {'count': items.length});
    return items;
  }

  Future<PurchaseOrderModel> get(String id) async {
    AppLogger.repo('purchase.get', {'id': id});
    final r = await _dio.get<dynamic>('/purchases/$id');
    return PurchaseOrderModel.fromJson(parseObject(r.data));
  }

  Future<PurchaseOrderModel> create(Map<String, dynamic> body) async {
    AppLogger.repo('purchase.create', {'body': body});
    final r = await _dio.post<dynamic>('/purchases', data: body);
    final result = PurchaseOrderModel.fromJson(parseObject(r.data));
    AppLogger.repo('purchase.create.ok', {'id': result.id});
    return result;
  }

  /// API: `PATCH /purchases/{id}/receive` with optional `{ "branch_id": "uuid" }`.
  Future<PurchaseOrderModel> receive(String id, {String? branchId}) async {
    AppLogger.repo('purchase.receive.start', {'id': id, 'branchId': branchId});
    final data = <String, dynamic>{
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
    };
    final r = await _dio.patch<dynamic>(
      '/purchases/$id/receive',
      data: data.isEmpty ? null : data,
    );
    final result = PurchaseOrderModel.fromJson(parseObject(r.data));
    AppLogger.repo('purchase.receive.ok', {'id': id, 'status': result.status});
    return result;
  }

  Future<void> cancel(String id) async {
    AppLogger.repo('purchase.cancel.start', {'id': id});
    await _dio.patch('/purchases/$id/cancel');
    AppLogger.repo('purchase.cancel.ok', {'id': id});
  }
}
