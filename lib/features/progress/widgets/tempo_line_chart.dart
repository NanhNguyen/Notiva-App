import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/progress_models.dart';

/// Brass-accent (#B8893B) line chart of manually recorded tempo over time.
class TempoLineChart extends StatelessWidget {
  const TempoLineChart({
    super.key,
    required this.points,
    this.height = 180,
  });

  final List<TempoDataPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TempoChartPainter(points),
      ),
    );
  }
}

class _TempoChartPainter extends CustomPainter {
  _TempoChartPainter(this.points);

  final List<TempoDataPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPad = 40.0;
    const rightPad = 12.0;
    const topPad = 12.0;
    const bottomPad = 24.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    var minT = points.first.tempo;
    var maxT = points.first.tempo;
    for (final p in points) {
      if (p.tempo < minT) minT = p.tempo;
      if (p.tempo > maxT) maxT = p.tempo;
    }
    if (minT == maxT) {
      minT = (minT - 10).clamp(20, 300);
      maxT = (maxT + 10).clamp(20, 300);
    }
    final range = (maxT - minT).toDouble();

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    // Draw 3 horizontal reference lines (min, mid, max).
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = topPad + chartHeight * (1 - frac);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
      final labelVal = (minT + range * frac).round();
      final tp = TextPainter(
        text: TextSpan(text: '$labelVal', style: AppTextStyles.caption),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 8, y - tp.height / 2));
    }

    final linePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? leftPad + chartWidth / 2
          : leftPad + (i / (points.length - 1)) * chartWidth;
      final norm = range == 0 ? 0.5 : (points[i].tempo - minT) / range;
      final y = topPad + chartHeight * (1 - norm);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    if (points.length > 1) {
      canvas.drawPath(path, linePaint);
    }

    // Draw first and last date labels on X axis.
    _paintDateLabel(
      canvas,
      points.first.date,
      leftPad,
      size.height - bottomPad + 6,
      alignRight: false,
    );
    if (points.length > 1) {
      _paintDateLabel(
        canvas,
        points.last.date,
        size.width - rightPad,
        size.height - bottomPad + 6,
        alignRight: true,
      );
    }
  }

  void _paintDateLabel(
    Canvas canvas,
    DateTime utcDate,
    double x,
    double y, {
    required bool alignRight,
  }) {
    final local = utcDate.toLocal();
    final label =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    final tp = TextPainter(
      text: TextSpan(text: label, style: AppTextStyles.caption),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? (x - tp.width) : x;
    tp.paint(canvas, Offset(dx, y));
  }

  @override
  bool shouldRepaint(covariant _TempoChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

