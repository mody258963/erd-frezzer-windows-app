import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';

class InstallmentRepository {
  InstallmentRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final r = await _dio.get<dynamic>('/installments');
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> overdue() async {
    final r = await _dio.get<dynamic>('/installments/overdue');
    return parseList(r.data, (j) => j);
  }

  Future<void> pay(String id, {String paymentMethod = 'cash'}) async {
    await _dio.post('/installments/$id/pay', data: {
      'payment_method': paymentMethod,
    });
  }
}
