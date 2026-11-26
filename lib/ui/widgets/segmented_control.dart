import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Option descriptor for [SegmentedControl].
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.selectedBorderColor,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? selectedBorderColor;
}

/// Pill-style 2- or 3-option segmented control (e.g. outcome or chart mode).
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : assert(options.length >= 2 && options.length <= 3);

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = option.value == selected;
        final bgColor = option.backgroundColor ??
            (isSelected
                ? AppColors.primaryContainer
                : AppColors.surfaceVariant);
        final fgColor = option.foregroundColor ??
            (isSelected ? AppColors.primary : AppColors.textSecondary);
        final borderColor = isSelected
            ? (option.selectedBorderColor ?? fgColor)
            : AppColors.border;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == options.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: option.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: AppRadius.borderFull,
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected && option.icon != null) ...[
                        Icon(option.icon, size: 18, color: fgColor),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(color: fgColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

