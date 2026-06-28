import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class FuturisticButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const FuturisticButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
    this.width,
    this.padding,
  });

  @override
  State<FuturisticButton> createState() => _FuturisticButtonState();
}

class _FuturisticButtonState extends State<FuturisticButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    
    final primaryGrad = isDisabled
        ? LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [AppColors.acentoVioleta, AppColors.acentoMagenta],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          
    final secondaryGrad = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.03),
        Colors.white.withValues(alpha: 0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered && !isDisabled ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: widget.width,
          decoration: BoxDecoration(
            gradient: widget.isSecondary ? secondaryGrad : primaryGrad,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? Colors.white.withValues(alpha: 0.12)
                  : widget.isSecondary
                      ? AppColors.acentoVioleta.withValues(alpha: 0.5)
                      : AppColors.acentoMagenta.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: _isHovered && !isDisabled
                ? [
                    BoxShadow(
                      color: (widget.isSecondary
                              ? AppColors.acentoVioleta
                              : AppColors.acentoMagenta)
                          .withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              splashColor: isDisabled ? Colors.transparent : AppColors.acentoMagenta.withValues(alpha: 0.2),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.text.toUpperCase(),
                      style: TextStyle(
                        color: isDisabled
                            ? AppColors.textoSecundario.withValues(alpha: 0.5)
                            : AppColors.textoPrincipal,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      widget.icon,
                      color: isDisabled
                          ? AppColors.textoSecundario.withValues(alpha: 0.5)
                          : AppColors.textoPrincipal,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
