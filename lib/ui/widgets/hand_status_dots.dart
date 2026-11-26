import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/enums/hand_status.dart';
import 'dashed_rect_painter.dart';

/// Compact R / L / H mini-key indicators for section list rows.
class HandStatusDots extends StatelessWidget {
  const HandStatusDots({
    super.key,
    required this.rh,
    required this.lh,
    required this.ht,
  });

  final HandStatus rh;
  final HandStatus lh;
  final HandStatus ht;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Tay phải: ${rh.label}, Tay trái: ${lh.label}, Hai tay: ${ht.label}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(letter: 'R', status: rh),
          const SizedBox(width: AppSpacing.sm),
          _StatusDot(letter: 'L', status: lh),
          const SizedBox(width: AppSpacing.sm),
          _StatusDot(letter: 'H', status: ht),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.letter,
    required this.status,
  });

  final String letter;
  final HandStatus status;

  double get _fillFraction => switch (status) {
        HandStatus.notStarted => 0.0,
        HandStatus.learning => 1 / 3,
        HandStatus.solid => 2 / 3,
        HandStatus.mastered => 1.0,
      };

  @override
  Widget build(BuildContext context) {
    final isNotStarted = status == HandStatus.notStarted;
    final fillColor = AppColors.statusColors[status.value];
    final borderColor = switch (status) {
      HandStatus.notStarted => AppColors.statusNotStarted,
      HandStatus.mastered => AppColors.statusMastered,
      _ => AppColors.border,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 10,
          height: 14,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderSm,
                  border: isNotStarted
                      ? null
                      : Border.all(color: borderColor, width: 1),
                ),
              ),
              if (!isNotStarted)
                ClipRRect(
                  borderRadius: AppRadius.borderSm,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: _fillFraction,
                      widthFactor: 1.0,
                      child: ColoredBox(color: fillColor),
                    ),
                  ),
                ),
              if (isNotStarted)
                CustomPaint(
                  painter: DashedRRectPainter(
                    color: borderColor,
                    radius: AppRadius.sm,
                    strokeWidth: 1,
                    dashWidth: 2,
                    dashGap: 2,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          letter,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

