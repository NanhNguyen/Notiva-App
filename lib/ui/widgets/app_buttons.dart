import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Primary filled pill button (52dp height, at most one per screen).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(label),
      ),
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Secondary tonal pill button (48dp min height, surfaceVariant + 1px border).
class TonalButton extends StatelessWidget {
  const TonalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceVariant,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
        side: const BorderSide(color: AppColors.border, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: AppTextStyles.label,
      ),
      child: Text(label),
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Tertiary text-only button (48dp min touch target).
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
        textStyle: AppTextStyles.label.copyWith(color: color),
      ),
      child: Text(label),
    );
  }
}

