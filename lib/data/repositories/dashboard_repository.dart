import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../../core/dashboard/dashboard_period.dart';
import '../models/supplier_payables_model.dart';
import '../models/dashboard_cash_collections.dart';

class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  static Map<String, dynamic> _query({
    String? branchId,
    DashboardPeriod? period,
    DateTime? anchorDate,
  }) =>
      dashboardPeriodQuery(
        period: period ?? DashboardPeriod.week,
        anchorDate: anchorDate,
        branchId: branchId,
      );

  Future<Map<String, dynamic>> summary({
    String? branchId,
    DashboardPeriod period = DashboardPeriod.week,
    DateTime? anchorDate,
  }) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/summary',
      queryParameters: _query(
        branchId: branchId,
        period: period,
        anchorDate: anchorDate,
      ),
    );
    return parseObject(r.data);
  }

  /// Realized cash boxes — actual cash in/out only.
  Future<Map<String, dynamic>> cash({
    String? branchId,
    DashboardPeriod period = DashboardPeriod.week,
    DateTime? anchorDate,
  }) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/cash',
      queryParameters: _query(
        branchId: branchId,
        period: period,
        anchorDate: anchorDate,
      ),
    );
    return parseObject(r.data);
  }

  /// Today's customer collection lines for drawer print (`GET /dashboard/cash/customer-collections`).
  Future<List<Map<String, dynamic>>> customerCollections({
    String? branchId,
    DashboardPeriod period = DashboardPeriod.day,
    DateTime? anchorDate,
  }) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/cash/customer-collections',
      queryParameters: _query(
        branchId: branchId,
        period: period,
        anchorDate: anchorDate,
      ),
    );
    final data = r.data;
    if (data is List) {
      return parseList(data, (j) => j);
    }
    if (data is Map) {
      final map = parseObject(data);
      final rows = DashboardCashCollectionsParser.rowsFromCashResponse(map);
      if (rows.isNotEmpty) return rows;
      final items = map['items'] ?? map['data'];
      if (items is List) {
        return parseList(items, (j) => j);
      }
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> inventory({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/inventory',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, (j) => j);
  }

  Future<List<Map<String, dynamic>>> receivables({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/receivables',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, (j) => j);
  }

  Future<Map<String, dynamic>> payables({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/payables',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseObject(r.data);
  }

  /// Grouped supplier debt with POs and installments per supplier.
  Future<SupplierPayablesResponse> payablesBySupplier({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/payables/by-supplier',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return SupplierPayablesResponse.fromJson(parseObject(r.data));
  }

  Future<Map<String, dynamic>> sales({
    String? branchId,
    DashboardPeriod period = DashboardPeriod.week,
    DateTime? anchorDate,
  }) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/sales',
      queryParameters: _query(
        branchId: branchId,
        period: period,
        anchorDate: anchorDate,
      ),
    );
    return parseObject(r.data);
  }

  Future<List<Map<String, dynamic>>> activity({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/dashboard/activity',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, (j) => j);
  }

  /// Sales broken down by product (falls back to reports endpoint shape).
  Future<List<Map<String, dynamic>>> productSales({String? branchId}) async {
    final r = await _dio.get<dynamic>(
      '/reports/sales',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseList(r.data, (j) => j);
  }
}
