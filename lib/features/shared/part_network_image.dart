import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/images/part_image_cache.dart';

/// Part thumbnail / preview backed by [PartImageCache] (disk + memory).
class PartNetworkImage extends StatelessWidget {
  const PartNetworkImage({
    required this.imageUrl,
    this.width = 40,
    this.height = 40,
    this.fit = BoxFit.cover,
    this.circular = true,
    this.placeholderIcon = Icons.inventory_2_outlined,
    super.key,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final bool circular;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }

    final image = CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: PartImageCache.manager,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );

    if (!circular) return image;

    return ClipOval(child: image);
  }

  Widget _placeholder() {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: const Color(0xFFE8EAF0),
        child: Icon(placeholderIcon, size: width * 0.55),
      ),
    );
  }
}
