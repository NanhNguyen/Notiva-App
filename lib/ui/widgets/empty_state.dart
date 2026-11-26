import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_buttons.dart';

/// Empty state with 5 thin outlined piano keys drawn via [CustomPainter],
/// title, subtitle, and a single primary action button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              excludeSemantics: true,
              child: const SizedBox(
                width: 120,
                height: 64,
                child: CustomPaint(
                  painter: _EmptyPianoKeysPainter(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: actionLabel,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPianoKeysPainter extends CustomPainter {
  const _EmptyPianoKeysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const keyCount = 5;
    const gap = 4.0;
    final keyWidth = (size.width - gap * (keyCount - 1)) / keyCount;

    final fillPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    for (var i = 0; i < keyCount; i++) {
      final left = i * (keyWidth + gap);
      final rect = Rect.fromLTWH(left, 0.75, keyWidth, size.height - 1.5);
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(AppRadius.sm / 2),
      );
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

