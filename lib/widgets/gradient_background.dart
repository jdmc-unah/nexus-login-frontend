import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'quantum_mailbox.dart';

class GradientBackground extends StatefulWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
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
      builder: (context, child) {
        final double t = _controller.value;
        // Slow circular movements for the two ambient glow centers
        final double x1 = 0.3 + 0.2 * cos(2 * pi * t);
        final double y1 = 0.3 + 0.2 * sin(2 * pi * t);
        final double x2 = 0.7 + 0.15 * sin(2 * pi * t + pi);
        final double y2 = 0.7 + 0.15 * cos(2 * pi * t + pi);

        return Scaffold(
          body: Stack(
            children: [
              // 1. Dark Base Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.fondoBase,
                      AppColors.fondoGradienteFin,
                    ],
                  ),
                ),
              ),
              // 2. Animated Ambient Glow 1
              Positioned.fill(
                child: CustomPaint(
                  painter: AmbientGlowPainter(
                    center: FractionalOffset(x1, y1),
                    color: AppColors.acentoVioleta.withValues(alpha: 0.15),
                    radius: 0.5,
                  ),
                ),
              ),
              // 3. Animated Ambient Glow 2
              Positioned.fill(
                child: CustomPaint(
                  painter: AmbientGlowPainter(
                    center: FractionalOffset(x2, y2),
                    color: AppColors.acentoMagenta.withValues(alpha: 0.12),
                    radius: 0.4,
                  ),
                ),
              ),
              // 4. Content
              SafeArea(
                child: widget.child,
              ),
              // 5. Simulated Inbox console (test)
              const QuantumMailbox(),
            ],
          ),
        );
      },
    );
  }
}

class AmbientGlowPainter extends CustomPainter {
  final FractionalOffset center;
  final Color color;
  final double radius;

  AmbientGlowPainter({
    required this.center,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(center.dx * size.width, center.dy * size.height),
          radius: size.shortestSide * radius,
        ),
      );

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant AmbientGlowPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}
