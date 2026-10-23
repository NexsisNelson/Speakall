import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpeakingOrb extends StatefulWidget {
  const SpeakingOrb({super.key, required this.isListening, this.size = 260});

  final bool isListening;
  final double size;

  @override
  State<SpeakingOrb> createState() => _SpeakingOrbState();
}

class _SpeakingOrbState extends State<SpeakingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final pulse = widget.isListening ? 0.85 + t * 0.15 : 0.97 + t * 0.03;
        final opacity = widget.isListening ? 0.55 + t * 0.45 : 0.7;

        return Transform.scale(
          scale: pulse,
          child: Opacity(
            opacity: opacity,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _OrbPainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint();
    const dotCount = 900;
    final goldenAngle = math.pi * (3 - math.sqrt(5));

    for (var i = 0; i < dotCount; i++) {
      final y = 1 - (i / (dotCount - 1)) * 2;
      final ringRadius = math.sqrt(1 - y * y);
      final theta = goldenAngle * i;
      final x = math.cos(theta) * ringRadius;
      final z = math.sin(theta) * ringRadius;
      final depth = (z + 1) / 2;

      paint.color = Colors.black.withValues(alpha: 0.15 + depth * 0.75);
      canvas.drawCircle(
        Offset(center.dx + x * radius, center.dy + y * radius),
        0.6 + depth * 1.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => false;
}
