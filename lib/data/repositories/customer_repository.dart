import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/linked_balance_model.dart';

class CustomerRepository {
  CustomerRepository(this._dio);
  final Dio _dio;

  Future<List<CustomerModel>> list({
    String? search,
    String? type,
    String? branchId,
    int perPage = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '/customers',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null) 'type': type,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
        'per_page': perPage,
      },
    );
    return parseList(response.data, CustomerModel.fromJson);
  }

  Future<CustomerModel> get(String id) async {
    final response = await _dio.get<dynamic>('/customers/$id');
    return CustomerModel.fromJson(parseObject(response.data));
  }

  Future<CustomerModel> create(
    Map<String, dynamic> body, {
    String? branchId,
  }) async {
    final response = await _dio.post<dynamic>(
      '/customers',
      data: body,
      queryParameters: branchId != null && branchId.isNotEmpty
          ? {'branch_id': branchId}
          : null,
    );
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

  Future<Map<String, dynamic>> collectPayment(
    String id, {
    required String paymentMethod,
    double? amount,
    String? notes,
  }) async {
    final response = await _dio.post<dynamic>(
      '/customers/$id/payments',
      data: {
        'payment_method': paymentMethod,
        if (amount != null) 'amount': amount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return parseObject(response.data);
  }

  Future<List<Map<String, dynamic>>> payments(
    String id, {
    int perPage = 25,
  }) async {
    final response = await _dio.get<dynamic>(
      '/customers/$id/payments',
      queryParameters: {'per_page': perPage},
    );
    return parseList(response.data, (j) => j);
  }

  Future<Map<String, dynamic>> updatePayment(
    String customerId,
    String paymentId, {
    double? amount,
    String? paymentMethod,
    String? notes,
  }) async {
    final response = await _dio.patch<dynamic>(
      '/customers/$customerId/payments/$paymentId',
      data: {
        if (amount != null) 'amount': amount,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (notes != null) 'notes': notes,
      },
    );
    return parseObject(response.data);
  }

  Future<LinkedBalanceModel> linkedBalance(String id) async {
    final response = await _dio.get<dynamic>('/customers/$id/linked-balance');
    return LinkedBalanceModel.fromJson(parseObject(response.data));
  }

  Future<Map<String, dynamic>> offsetSupplier(
    String id, {
    double? amount,
    String? notes,
  }) async {
    final response = await _dio.post<dynamic>(
      '/customers/$id/offset-supplier',
      data: {
        if (amount != null) 'amount': amount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return parseObject(response.data);
  }

  Future<List<Map<String, dynamic>>> contraSettlements(
    String id, {
    int perPage = 25,
  }) async {
    final response = await _dio.get<dynamic>(
      '/customers/$id/contra-settlements',
      queryParameters: {'per_page': perPage},
    );
    return parseList(response.data, (j) => j);
  }
}
