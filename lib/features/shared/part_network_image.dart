import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/images/part_image_cache.dart';
import 'image_lightbox.dart';

/// Part thumbnail / preview backed by [PartImageCache] (disk + memory).
/// Tap to open full-screen lightbox when [enableLightbox] is true.
class PartNetworkImage extends StatelessWidget {
  const PartNetworkImage({
    required this.imageUrl,
    this.width = 40,
    this.height = 40,
    this.fit = BoxFit.cover,
    this.circular = true,
    this.placeholderIcon = Icons.inventory_2_outlined,
    this.enableLightbox = true,
    super.key,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final bool circular;
  final IconData placeholderIcon;
  final bool enableLightbox;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (!enableLightbox || imageUrl == null || imageUrl!.isEmpty) {
      return content;
    }

    return LightboxTapTarget(
      onTap: () => showImageLightbox(context, networkUrl: imageUrl),
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
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
