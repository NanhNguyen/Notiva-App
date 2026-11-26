import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/enums/hand_status.dart';
import 'dashed_rect_painter.dart';

/// Practice hand dimension for [HandStatusStepper].
enum PracticeHand {
  rh('Tay phải (RH)'),
  lh('Tay trái (LH)'),
  ht('Hai tay (HT)');

  const PracticeHand(this.label);

  final String label;
}

/// Three-row status stepper (Tay phải, Tay trái, Hai tay) with 4 keys per row.
///
/// Optionally accepts [beforeRh], [beforeLh], [beforeHt] to show previous
/// levels faded when logging a practice session.
class HandStatusStepper extends StatelessWidget {
  const HandStatusStepper({
    super.key,
    required this.rh,
    required this.lh,
    required this.ht,
    this.beforeRh,
    this.beforeLh,
    this.beforeHt,
    required this.onChanged,
  });

  final HandStatus rh;
  final HandStatus lh;
  final HandStatus ht;
  final HandStatus? beforeRh;
  final HandStatus? beforeLh;
  final HandStatus? beforeHt;
  final void Function(PracticeHand hand, HandStatus level) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HandStatusRow(
          hand: PracticeHand.rh,
          current: rh,
          before: beforeRh,
          onSelect: (level) => _handleSelect(PracticeHand.rh, rh, level),
        ),
        const SizedBox(height: AppSpacing.md),
        _HandStatusRow(
          hand: PracticeHand.lh,
          current: lh,
          before: beforeLh,
          onSelect: (level) => _handleSelect(PracticeHand.lh, lh, level),
        ),
        const SizedBox(height: AppSpacing.md),
        _HandStatusRow(
          hand: PracticeHand.ht,
          current: ht,
          before: beforeHt,
          onSelect: (level) => _handleSelect(PracticeHand.ht, ht, level),
        ),
      ],
    );
  }

  void _handleSelect(
    PracticeHand hand,
    HandStatus current,
    HandStatus next,
  ) {
    if (current != next) {
      HapticFeedback.lightImpact();
      onChanged(hand, next);
    }
  }
}

class _HandStatusRow extends StatelessWidget {
  const _HandStatusRow({
    required this.hand,
    required this.current,
    required this.before,
    required this.onSelect,
  });

  final PracticeHand hand;
  final HandStatus current;
  final HandStatus? before;
  final ValueChanged<HandStatus> onSelect;

  bool get _hasChanged => before != null && before != current;

  @override
  Widget build(BuildContext context) {
    final cardColor = _hasChanged
        ? AppColors.primaryContainer.withValues(alpha: 0.35)
        : AppColors.surface;
    final borderColor = _hasChanged
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.border;
    final statusText = _hasChanged
        ? '${before!.label} → ${current.label}'
        : current.label;
    final statusColor =
        _hasChanged ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hand.label, style: AppTextStyles.label),
              Text(
                statusText,
                style: AppTextStyles.caption.copyWith(color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(HandStatus.values.length, (index) {
              final level = HandStatus.values[index];
              final isSelected = level == current;
              final isBefore = _hasChanged && level == before;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == HandStatus.values.length - 1 ? 0 : 4,
                  ),
                  child: _StepperKey(
                    hand: hand,
                    level: level,
                    isSelected: isSelected,
                    isBefore: isBefore,
                    hasChangedFromBefore: _hasChanged,
                    onTap: () => onSelect(level),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepperKey extends StatelessWidget {
  const _StepperKey({
    required this.hand,
    required this.level,
    required this.isSelected,
    required this.isBefore,
    required this.hasChangedFromBefore,
    required this.onTap,
  });

  final PracticeHand hand;
  final HandStatus level;
  final bool isSelected;
  final bool isBefore;
  final bool hasChangedFromBefore;
  final VoidCallback onTap;

  double get _fillFraction => switch (level) {
        HandStatus.notStarted => 0.0,
        HandStatus.learning => 1 / 3,
        HandStatus.solid => 2 / 3,
        HandStatus.mastered => 1.0,
      };

  Color get _fillColor => AppColors.statusColors[level.value];

  @override
  Widget build(BuildContext context) {
    final showFill = (isSelected || isBefore) && level != HandStatus.notStarted;
    final selectedBorderColor =
        hasChangedFromBefore ? AppColors.primary : AppColors.textPrimary;

    Widget keyBox = SizedBox(
      height: 36,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderSm,
              border: _solidBorder(selectedBorderColor),
            ),
          ),
          if (showFill)
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: _fillFraction,
                  widthFactor: 1.0,
                  child: ColoredBox(color: _fillColor),
                ),
              ),
            ),
          if (_usesDashedBorder)
            CustomPaint(
              painter: DashedRRectPainter(
                color: _dashedBorderColor(selectedBorderColor),
                radius: AppRadius.sm,
                strokeWidth: isSelected ? 2.0 : 1.0,
              ),
            ),
        ],
      ),
    );

    if (isBefore) {
      keyBox = Opacity(opacity: 0.45, child: keyBox);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${hand.label}: ${level.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(child: keyBox),
        ),
      ),
    );
  }

  bool get _usesDashedBorder =>
      isBefore || (level == HandStatus.notStarted && !isSelected) || (level == HandStatus.notStarted && isSelected);

  Border? _solidBorder(Color selectedBorderColor) {
    if (_usesDashedBorder) return null;
    if (isSelected) {
      return Border.all(color: selectedBorderColor, width: 2);
    }
    return Border.all(color: AppColors.border, width: 1);
  }

  Color _dashedBorderColor(Color selectedBorderColor) {
    if (isSelected && level == HandStatus.notStarted) {
      return selectedBorderColor;
    }
    if (isBefore) {
      return level == HandStatus.notStarted
          ? AppColors.textSecondary
          : _fillColor;
    }
    return AppColors.statusNotStarted;
  }
}

