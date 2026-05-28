import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum StatusChipVariant { success, warning, neutral, info }

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    super.key,
    this.variant = StatusChipVariant.neutral,
    this.showDot = true,
  });

  final String label;
  final StatusChipVariant variant;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = switch (variant) {
      StatusChipVariant.success => (
          AppColors.successContainer,
          AppColors.onSuccessContainer,
          AppColors.success,
        ),
      StatusChipVariant.warning => (
          AppColors.warningContainer,
          AppColors.onWarningContainer,
          AppColors.warning,
        ),
      StatusChipVariant.info => (
          AppColors.primaryContainer,
          AppColors.onPrimaryContainer,
          AppColors.primary,
        ),
      StatusChipVariant.neutral => (
          AppColors.outline.withValues(alpha: 0.5),
          AppColors.onSurfaceVariant,
          AppColors.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Icon(Icons.circle, size: 8, color: dot),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
