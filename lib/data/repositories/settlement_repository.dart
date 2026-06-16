import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/settlement_upcoming_model.dart';

class SettlementRepository {
  SettlementRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final r = await _dio.get<dynamic>('/settlements');
    return parseList(r.data, (j) => j);
  }

  Future<List<SettlementUpcomingRow>> upcoming({String? settlementCycle}) async {
    final r = await _dio.get<dynamic>(
      '/settlements/upcoming',
      queryParameters: settlementCycle != null && settlementCycle.isNotEmpty
          ? {'settlement_cycle': settlementCycle}
          : null,
    );
    return parseList(r.data, SettlementUpcomingRow.fromJson);
  }

  Future<Map<String, dynamic>> get(String id) async {
    final r = await _dio.get<dynamic>('/settlements/$id');
    return parseObject(r.data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final r = await _dio.post<dynamic>('/settlements', data: body);
    return parseObject(r.data);
  }
}
