import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Selectable or static pill chip matching docs/design.md 6.5.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        selected ? AppColors.primaryContainer : AppColors.surfaceVariant;
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final textColor = selected ? AppColors.primary : AppColors.textPrimary;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Center(
        widthFactor: 1.0,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: textColor),
        ),
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(widthFactor: 1.0, child: chip),
        ),
      ),
    );
  }
}

