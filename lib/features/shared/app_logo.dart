import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';

/// App brand mark from [AppAssets.logo].
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.circular = true,
  });

  final double size;
  final bool circular;

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

    if (!circular) return image;

    return ClipOval(
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}
