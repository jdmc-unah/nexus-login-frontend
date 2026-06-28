import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GlowCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final bool animateFloating;
  final EdgeInsetsGeometry? padding;

  const GlowCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.animateFloating = true,
    this.padding,
  });

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animateFloating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final floatOffset = widget.animateFloating ? _animation.value : 0.0;
        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 35 + (widget.animateFloating ? floatOffset * 0.8 : 0),
                  spreadRadius: 2,
                  offset: Offset(0, 15 + floatOffset * 0.3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.acentoVioleta.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
