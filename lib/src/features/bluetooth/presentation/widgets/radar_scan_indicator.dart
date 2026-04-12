import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RadarScanIndicator extends StatefulWidget {
  const RadarScanIndicator({super.key});

  @override
  State<RadarScanIndicator> createState() => _RadarScanIndicatorState();
}

class _RadarScanIndicatorState extends State<RadarScanIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96.w,
      height: 96.w,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarScanPainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _RadarScanPainter extends CustomPainter {
  const _RadarScanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFEBF3FF),
          const Color(0xFFEBF3FF).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.9, haloPaint);

    final startAngle = -pi / 2 + (progress * pi * 2);
    final sweepAngle = pi * 0.92;
    final sectorRect = Rect.fromCircle(center: center, radius: radius * 0.74);
    final sectorPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          const Color(0xFF7EAEFF).withOpacity(0.0),
          const Color(0xFF7EAEFF).withOpacity(0.18),
          const Color(0xFF7EAEFF).withOpacity(0.46),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(sectorRect);
    canvas.drawArc(sectorRect, startAngle, sweepAngle, true, sectorPaint);

    final armPaint = Paint()
      ..color = const Color(0xFFA8C6FF).withOpacity(0.35)
      ..strokeWidth = 1;
    final endPoint = Offset(
      center.dx + cos(startAngle + sweepAngle) * radius * 0.74,
      center.dy + sin(startAngle + sweepAngle) * radius * 0.74,
    );
    canvas.drawLine(center, endPoint, armPaint);

    final dotPaint = Paint()..color = const Color(0xFF5F98FF);
    canvas.drawCircle(center, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarScanPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
