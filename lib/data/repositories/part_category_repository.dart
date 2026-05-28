import 'package:dio/dio.dart';

import '../../core/api/api_utils.dart';
import '../models/part_category_model.dart';

class PartCategoryRepository {
  PartCategoryRepository(this._dio);
  final Dio _dio;

  Future<List<PartCategoryModel>> list({bool activeOnly = true}) async {
    final response = await _dio.get<dynamic>(
      '/part-categories',
      queryParameters: {'active_only': activeOnly},
    );
    return parseList(response.data, PartCategoryModel.fromJson);
  }

  Future<List<PartUnitOption>> listUnits() async {
    final response = await _dio.get<dynamic>('/part-units');
    final data = parseObject(response.data);
    final units = data['units'];
    if (units is! List) return [];
    return units
        .map((e) => PartUnitOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PartCategoryModel> create({
    required String key,
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    final response = await _dio.post<dynamic>(
      '/part-categories',
      data: {
        'key': key,
        'name': name,
        'sort_order': sortOrder,
        'is_active': isActive,
      },
    );
    return PartCategoryModel.fromJson(parseObject(response.data));
  }

  Future<PartCategoryModel> update(
    String id, {
    String? key,
    String? name,
    int? sortOrder,
    bool? isActive,
  }) async {
    final response = await _dio.put<dynamic>(
      '/part-categories/$id',
      data: {
        if (key != null) 'key': key,
        if (name != null) 'name': name,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return PartCategoryModel.fromJson(parseObject(response.data));
  }

  Future<void> deactivate(String id) async {
    await _dio.delete('/part-categories/$id');
  }
}
