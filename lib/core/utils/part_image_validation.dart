import 'dart:io';

const int kMaxPartImageBytes = 2 * 1024 * 1024;

const _allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

/// Returns a localization key suffix or null if valid.
/// Use with l10n: `partImageTooLarge`, `partImageInvalidType`.
String? validatePartImagePath(String path) {
  final ext = _extension(path);
  if (!_allowedExtensions.contains(ext)) {
    return 'invalid_type';
  }
  final file = File(path);
  if (!file.existsSync()) return 'invalid_type';
  if (file.lengthSync() > kMaxPartImageBytes) {
    return 'too_large';
  }
  return null;
}

String _extension(String path) {
  final i = path.lastIndexOf('.');
  if (i < 0) return '';
  return path.substring(i).toLowerCase();
}
