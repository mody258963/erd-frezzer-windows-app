import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import 'image_lightbox.dart';

/// App brand mark from [AppAssets.logo].
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.circular = true,
    this.enableLightbox = true,
  });

  final double size;
  final bool circular;
  final bool enableLightbox;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        Icons.ac_unit,
        size: size * 0.7,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );

    final clipped = circular
        ? ClipOval(child: SizedBox(width: size, height: size, child: image))
        : image;

    if (!enableLightbox) return clipped;

    return LightboxTapTarget(
      onTap: () => showImageLightbox(context, assetPath: AppAssets.logo),
      child: clipped,
    );
  }
}
