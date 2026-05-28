import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for part photos (used offline after catalog sync prefetch).
class PartImageCache {
  PartImageCache._();

  static final CacheManager manager = CacheManager(
    Config(
      'frostparts_part_images',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );

  static Future<void> prefetch(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await manager.downloadFile(url);
    } catch (_) {}
  }

  static Future<void> prefetchAll(Iterable<String?> urls) async {
    final seen = <String>{};
    for (final url in urls) {
      if (url == null || url.isEmpty || !seen.add(url)) continue;
      await prefetch(url);
    }
  }

  static Future<void> evict(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await manager.removeFile(url);
    } catch (_) {}
  }
}
