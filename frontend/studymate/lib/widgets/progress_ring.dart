import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/helpers.dart';

// the round progress chart shown on the dashboard and progress screen
class ProgressRing extends StatelessWidget {
  final double percent; // 0 to 100
  final double size;
  final double stroke;
  final Color color;
  final String? caption;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 110,
    this.stroke = 11,
    this.color = doneColor,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percent: percent, stroke: stroke, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                percentLabel(percent),
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: TextStyle(fontSize: size * 0.1, color: const Color(0xFF6B7280)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final double stroke;
  final Color color;

  _RingPainter({required this.percent, required this.stroke, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final background = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final foreground = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, background);
    // start at 12 o'clock and go clockwise
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent / 100, false, foreground);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.color != color || old.stroke != stroke;
}
