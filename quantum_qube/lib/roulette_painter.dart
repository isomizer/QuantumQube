import 'dart:math';
import 'package:flutter/material.dart';

class RoulettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final paint = Paint()
      ..style = PaintingStyle.fill;
    const sectors = 12;
    final colors = [Colors.red, Colors.black];
    for (int i = 0; i < sectors; i++) {
      paint.color = colors[i % 2];
      final startAngle = (2 * pi / sectors) * i;
      final sweepAngle = 2 * pi / sectors;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);
    }
    // Draw center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
