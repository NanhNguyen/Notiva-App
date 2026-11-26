import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Minus / value + unit / plus stepper for tempo (bpm) or duration (minutes).
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.min = 20,
    this.max = 300,
    this.step = 2,
    this.subtitle,
  });

  final int value;
  final String unit;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final canDecrement = value - step >= min;
    final canIncrement = value + step <= max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _CircleStepButton(
              icon: Icons.remove,
              semanticLabel: 'Giảm $unit',
              enabled: canDecrement,
              onTap: canDecrement ? () => onChanged(value - step) : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: AppTextStyles.heading.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      unit,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _CircleStepButton(
              icon: Icons.add,
              semanticLabel: 'Tăng $unit',
              enabled: canIncrement,
              onTap: canIncrement ? () => onChanged(value + step) : null,
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

class _CircleStepButton extends StatelessWidget {
  const _CircleStepButton({
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: Container(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

