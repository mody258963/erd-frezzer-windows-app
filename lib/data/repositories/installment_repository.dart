import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../../core/logging/app_logger.dart';
import '../models/supplier_installment_model.dart';

class InstallmentRepository {
  InstallmentRepository(this._dio);
  final Dio _dio;

  Future<List<SupplierInstallmentModel>> list() async {
    final r = await _dio.get<dynamic>('/installments');
    return parseList(r.data, SupplierInstallmentModel.fromJson);
  }

  Future<List<SupplierInstallmentModel>> overdue() async {
    final r = await _dio.get<dynamic>('/installments/overdue');
    return parseList(r.data, SupplierInstallmentModel.fromJson);
  }

  /// Unpaid installments for one supplier (`?supplier_id=` or client filter).
  Future<List<SupplierInstallmentModel>> listForSupplier(String supplierId) async {
    try {
      final r = await _dio.get<dynamic>(
        '/installments',
        queryParameters: {'supplier_id': supplierId},
      );
      final rows = parseList(r.data, SupplierInstallmentModel.fromJson);
      if (rows.isNotEmpty) {
        return rows.where((i) => i.canPay).toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 422) {
        rethrow;
      }
    }
    final all = await list();
    return all
        .where((i) => i.supplierId == supplierId && i.canPay)
        .toList();
  }

  Future<void> pay(
    String id, {
    required String paymentMethod,
    double? amount,
    String? notes,
  }) async {
    AppLogger.repo('installment.pay', {
      'id': id,
      'paymentMethod': paymentMethod,
      if (amount != null) 'amount': amount,
    });
    await _dio.post('/installments/$id/pay', data: {
      'payment_method': paymentMethod,
      if (amount != null) 'amount': amount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    AppLogger.repo('installment.pay.ok', {'id': id});
  }
}
