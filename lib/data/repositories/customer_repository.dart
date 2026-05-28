import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';

class CustomerRepository {
  CustomerRepository(this._dio);
  final Dio _dio;

  Future<List<CustomerModel>> list({
    String? search,
    String? type,
    int perPage = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '/customers',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null) 'type': type,
        'per_page': perPage,
      },
    );
    return parseList(response.data, CustomerModel.fromJson);
  }

  Future<CustomerModel> get(String id) async {
    final response = await _dio.get<dynamic>('/customers/$id');
    return CustomerModel.fromJson(parseObject(response.data));
  }

  Future<CustomerModel> create(Map<String, dynamic> body) async {
    final response = await _dio.post<dynamic>('/customers', data: body);
    return CustomerModel.fromJson(parseObject(response.data));
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> body) async {
    final response = await _dio.put<dynamic>('/customers/$id', data: body);
    return CustomerModel.fromJson(parseObject(response.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete('/customers/$id');
  }

  Future<List<InvoiceModel>> invoices(String id) async {
    final response = await _dio.get<dynamic>('/customers/$id/invoices');
    return parseList(response.data, InvoiceModel.fromJson);
  }

  Future<Map<String, dynamic>> balance(String id) async {
    final response = await _dio.get<dynamic>('/customers/$id/balance');
    return parseObject(response.data);
  }
}
