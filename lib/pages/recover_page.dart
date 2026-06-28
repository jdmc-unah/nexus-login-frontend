import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glow_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/futuristic_button.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

class RecoverPage extends StatefulWidget {
  const RecoverPage({super.key});

  @override
  State<RecoverPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends State<RecoverPage> {
  int _currentStep = 0; // 0 = Option Selection, 1 = Email Input, 2 = Code & New Password, 3 = Success Feedback
  String _selectedOption = ''; // 'Usuario' or 'Contraseña'
  
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
      _currentStep = 1;
    });
  }

  void _handleSendEmail() async {
    if (_emailFormKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      final res = await ApiService.recover(_emailController.text.trim(), _selectedOption);

      setState(() {
        _isProcessing = false;
      });

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Código encolado. Revisa tu Buzón Cuántico.'),
            backgroundColor: AppColors.acentoVioleta,
          ),
        );
        setState(() {
          if (_selectedOption == 'Usuario') {
            _currentStep = 3; // Direct success since username is sent to mail
          } else {
            _currentStep = 2; // Prompt for verification code and new password
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'No se pudo enviar el correo de recuperación.'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  void _handleResetPasswordSubmit() async {
    if (_resetFormKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las contraseñas no coinciden.'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      final res = await ApiService.resetPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _newPasswordController.text,
      );

      setState(() {
        _isProcessing = false;
      });

      if (res['success'] == true) {
        setState(() {
          _currentStep = 3;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Error al restablecer la contraseña.'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  void _resetFlow() {
    setState(() {
      _currentStep = 0;
      _selectedOption = '';
      _emailController.clear();
      _codeController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back Button navigation
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textoSecundario,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_currentStep == 1) {
                        _resetFlow();
                      } else if (_currentStep == 2) {
                        setState(() {
                          _currentStep = 1;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    tooltip: 'Volver',
                  ),
                ),
              ),

              // Central Floating Card
              Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: GlowCard(
                  animateFloating: false,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0OptionSelection();
      case 1:
        return _buildStep1EmailInput();
      case 2:
        return _buildStep2CodeAndNewPassword();
      case 3:
        return _buildStep3SuccessFeedback();
      default:
        return _buildStep0OptionSelection();
    }
  }

  Widget _buildStep0OptionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '¿QUÉ OLVIDÓ?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecciona la credencial que deseas recuperar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 40),
        
        _RecoveryOptionCard(
          title: 'Olvidé mi Usuario',
          subtitle: 'Recupera el identificador único de tu nodo',
          icon: Icons.alternate_email_rounded,
          color: AppColors.acentoMagenta,
          onTap: () => _selectOption('Usuario'),
        ),
        const SizedBox(height: 20),
        _RecoveryOptionCard(
          title: 'Olvidé mi Contraseña',
          subtitle: 'Restablece tu llave de seguridad cuántica',
          icon: Icons.lock_reset_rounded,
          color: AppColors.acentoVioleta,
          onTap: () => _selectOption('Contraseña'),
        ),
      ],
    );
  }

  Widget _buildStep1EmailInput() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RECUPERAR ${_selectedOption.toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu email registrado para enviar las instrucciones.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 36),

          CustomTextField(
            labelText: 'Email Registrado',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu email.';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Ingresa una dirección de email válida.';
              }
              return null;
            },
          ),
          const SizedBox(height: 36),

          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.acentoMagenta),
            )
          else
            FuturisticButton(
              text: 'Enviar Instrucciones',
              icon: Icons.send_rounded,
              onPressed: _handleSendEmail,
            ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _resetFlow,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textoSecundario,
            ),
            child: const Text('Cancelar y Volver'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2CodeAndNewPassword() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RESTABLECER ACCESO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el código enviado a ${_emailController.text} y tu nueva contraseña.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          CustomTextField(
            labelText: 'Código Cuántico (6 dígitos)',
            prefixIcon: Icons.pin_rounded,
            controller: _codeController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa el código recibido.';
              }
              if (value.trim().length != 6) {
                return 'Debe ser de 6 dígitos.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            labelText: 'Nueva Contraseña de Acceso',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            controller: _newPasswordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña.';
              }
              if (value.length < 6) {
                return 'Debe contener al menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            labelText: 'Confirmar Contraseña',
            prefixIcon: Icons.lock_clock_outlined,
            obscureText: true,
            controller: _confirmPasswordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor confirma tu contraseña.';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.acentoMagenta),
            )
          else
            FuturisticButton(
              text: 'Restablecer Contraseña',
              icon: Icons.vpn_key_outlined,
              onPressed: _handleResetPasswordSubmit,
            ),
        ],
      ),
    );
  }

  Widget _buildStep3SuccessFeedback() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.acentoVioleta.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.acentoVioleta, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.acentoVioleta.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            _selectedOption == 'Usuario' ? Icons.badge_outlined : Icons.lock_outline_rounded,
            size: 48,
            color: AppColors.acentoMagenta,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          _selectedOption == 'Usuario' ? 'FIRMA ENVIADA' : 'CONTRASEÑA ACTUALIZADA',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: _selectedOption == 'Usuario'
                    ? 'Se ha enviado tu nombre de usuario al correo:\n'
                    : 'Tu contraseña cuántica ha sido modificada con éxito para:\n',
              ),
              TextSpan(
                text: _emailController.text,
                style: const TextStyle(
                  color: AppColors.acentoMagenta,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '\n\nYa puedes volver al portal cuántico principal para iniciar sesión.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        FuturisticButton(
          text: 'Volver al Portal',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
          isSecondary: true,
          width: double.infinity,
        ),
      ],
    );
  }
}

class _RecoveryOptionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RecoveryOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RecoveryOptionCard> createState() => _RecoveryOptionCardState();
}

class _RecoveryOptionCardState extends State<_RecoveryOptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.04 : 0.01),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? widget.color : AppColors.acentoVioleta.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: widget.color.withValues(alpha: 0.15),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.08),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.textoPrincipal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _isHovered ? widget.color : AppColors.textoSecundario.withValues(alpha: 0.5),
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
