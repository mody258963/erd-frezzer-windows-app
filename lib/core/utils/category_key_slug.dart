/// Converts a display name to a valid part category `key` (a-z, 0-9, _).
String slugifyCategoryKey(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

bool isValidCategoryKey(String key) =>
    key.isNotEmpty && RegExp(r'^[a-z0-9_]+$').hasMatch(key);
