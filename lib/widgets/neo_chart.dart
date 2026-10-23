import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Grafik histori suhu minimalis Neobrutalism (CustomPainter)
class NeoChart extends StatelessWidget {
  const NeoChart({
    super.key,
    required this.values,
    this.height = 100,
    this.strokeColor = NeoColors.ink,
    this.fillColor = const Color(0xFFFEF08A),
  });

  final List<double> values;
  final double height;
  final Color strokeColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'DATA HISTORI BELUM TERSEDIA',
            style: TextStyle(
              fontFamily: NeoText.display,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: NeoColors.textMuted,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _NeoChartPainter(
          values: values,
          strokeColor: strokeColor,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class _NeoChartPainter extends CustomPainter {
  _NeoChartPainter({
    required this.values,
    required this.strokeColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color strokeColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      // Jika hanya ada 1 nilai
      final p = Paint()
        ..color = strokeColor
        ..strokeWidth = 2.5;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        p,
      );
      return;
    }

    final double minVal = values.reduce(math.min);
    final double maxVal = values.reduce(math.max);
    final double range = (maxVal - minVal) < 1.0 ? 1.0 : (maxVal - minVal);

    // Padding agar garis tidak mentok border
    const double padY = 16.0;
    const double padX = 8.0;
    final double usableW = size.width - (padX * 2);
    final double usableH = size.height - (padY * 2);

    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = padX + (i / (values.length - 1)) * usableW;
      final double norm = (values[i] - minVal) / range;
      final double y = size.height - padY - (norm * usableH);
      points.add(Offset(x, y));
    }

    // Gambar grid horizontal brutalist (titik-titik / garis tipis)
    final gridPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.5;
    for (int g = 0; g <= 2; g++) {
      final double gy = padY + (g / 2) * usableH;
      canvas.drawLine(Offset(padX, gy), Offset(size.width - padX, gy), gridPaint);
    }

    // Path area isi (fill) di bawah kurva
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Garis stroke utama
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Titik poin dengan border hitam (sticker dots)
    final dotOuterPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = NeoColors.yellow
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 5.0, dotOuterPaint);
      canvas.drawCircle(pt, 3.0, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeoChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor;
  }
}
