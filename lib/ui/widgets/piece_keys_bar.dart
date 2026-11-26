import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/enums/hand_status.dart';
import 'dashed_rect_painter.dart';

/// Signature element of Notiva: a horizontal row of rounded piano keys,
/// one key per section, filled from the bottom according to HT [HandStatus].
class PieceKeysBar extends StatelessWidget {
  const PieceKeysBar({
    super.key,
    required this.statuses,
    this.sectionLabels,
    this.caption,
    this.compact = false,
    this.onKeyTap,
  });

  final List<HandStatus> statuses;
  final List<String>? sectionLabels;
  final String? caption;
  final bool compact;
  final ValueChanged<int>? onKeyTap;

  static const double _gap = 3.0;
  static const double _defaultHeight = 28.0;
  static const double _compactHeight = 20.0;
  static const double _minKeyWidth = 16.0;

  @override
  Widget build(BuildContext context) {
    final keyHeight = compact ? _compactHeight : _defaultHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(statuses.length, (index) {
            final status = statuses[index];
            final sectionName =
                (sectionLabels != null && index < sectionLabels!.length)
                    ? sectionLabels![index]
                    : 'Đoạn ${index + 1}';
            final semanticLabel =
                '$sectionName, hai tay: ${status.label.toLowerCase()}';

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == statuses.length - 1 ? 0 : _gap,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: _minKeyWidth),
                  child: _PieceKey(
                    status: status,
                    height: keyHeight,
                    semanticLabel: semanticLabel,
                    onTap: onKeyTap == null ? null : () => onKeyTap!(index),
                  ),
                ),
              ),
            );
          }),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(caption!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

class _PieceKey extends StatelessWidget {
  const _PieceKey({
    required this.status,
    required this.height,
    required this.semanticLabel,
    this.onTap,
  });

  final HandStatus status;
  final double height;
  final String semanticLabel;
  final VoidCallback? onTap;

  double get _fillFraction => switch (status) {
        HandStatus.notStarted => 0.0,
        HandStatus.learning => 1 / 3,
        HandStatus.solid => 2 / 3,
        HandStatus.mastered => 1.0,
      };

  Color get _fillColor => AppColors.statusColors[status.value];

  @override
  Widget build(BuildContext context) {
    final isNotStarted = status == HandStatus.notStarted;
    final borderColor = switch (status) {
      HandStatus.notStarted => AppColors.statusNotStarted,
      HandStatus.mastered => AppColors.statusMastered,
      _ => AppColors.border,
    };

    Widget keyVisual = SizedBox(
      height: height,
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
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  heightFactor: _fillFraction,
                  widthFactor: 1.0,
                  child: ColoredBox(color: _fillColor),
                ),
              ),
            ),
          if (isNotStarted)
            CustomPaint(
              painter: DashedRRectPainter(
                color: borderColor,
                radius: AppRadius.sm,
                strokeWidth: 1.2,
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      keyVisual = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(child: keyVisual),
        ),
      );
    }

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: keyVisual,
    );
  }
}

