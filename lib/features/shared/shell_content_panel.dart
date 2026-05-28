import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Frames main shell content in a padded card for clearer separation from the nav rail.
class ShellContentPanel extends StatelessWidget {
  const ShellContentPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.borderRadius),
          side: const BorderSide(color: AppColors.outline),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}
