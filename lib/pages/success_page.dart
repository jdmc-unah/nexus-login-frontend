import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glow_card.dart';
import '../widgets/futuristic_button.dart';
import '../core/theme/app_colors.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlowCard(
              animateFloating: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated glowing badge
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.acentoMagenta.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.acentoMagenta,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.acentoMagenta.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: AppColors.acentoMagenta,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Success Message
                  const Text(
                    '¡CUENTA CREADA CON ÉXITO!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu firma digital ha sido registrada en el nodo central. Tu acceso ahora está activo y verificado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Return Button
                  FuturisticButton(
                    text: 'Volver al Inicio',
                    icon: Icons.home_filled,
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    isSecondary: false,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
