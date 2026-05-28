import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/api/api_utils.dart';
import '../models/part_model.dart';

class PartRepository {
  PartRepository(this._dio);
  final Dio _dio;

  Future<List<PartModel>> list({String? search, int perPage = 50}) async {
    final response = await _dio.get<dynamic>(
      '/parts',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'per_page': perPage,
      },
    );
    return parseList(response.data, PartModel.fromJson);
  }

  Future<PartModel> get(String id) async {
    final response = await _dio.get<dynamic>('/parts/$id');
    return PartModel.fromJson(parseObject(response.data));
  }

  Future<PartModel> create(Map<String, dynamic> body) async {
    final response = await _dio.post<dynamic>('/parts', data: body);
    return PartModel.fromJson(parseObject(response.data));
  }

  Future<PartModel> update(String id, Map<String, dynamic> body) async {
    final response = await _dio.put<dynamic>('/parts/$id', data: body);
    return PartModel.fromJson(parseObject(response.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete('/parts/$id');
  }

  Future<PartModel> uploadImage(
    String id,
    String filePath,
  ) async {
    final fileName = p.basename(filePath);
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post<dynamic>(
      '/parts/$id/image',
      data: formData,
    );
    return PartModel.fromJson(parseObject(response.data));
  }

  Future<void> deleteImage(String id) async {
    await _dio.delete('/parts/$id/image');
  }

  /// `GET /parts/{id}/analysis` — stock, sales, purchases, returns, movements.
  Future<Map<String, dynamic>> analysis(
    String id, {
    String? from,
    String? to,
    String? branchId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/parts/$id/analysis',
      queryParameters: {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      },
    );
    return parseObject(response.data);
  }
}
