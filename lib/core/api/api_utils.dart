List<T> parseList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is List) {
    return data
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  if (data is Map) {
    if (data['data'] is List) {
      return (data['data'] as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  }
  return [];
}

Map<String, dynamic> parseObject(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data.containsKey('data') && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return data;
  }
  throw const FormatException('Invalid API response');
}
