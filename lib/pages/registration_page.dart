import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glow_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/futuristic_button.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/face_scanner_widget.dart';
import 'success_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _verifyFormKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isProcessing = false;
  bool _showVerification = false; // true = Muestra formulario para ingresar el código
  bool _showFaceLinkPrompt = false;
  bool _showScanner = false;
  String? _capturedFaceBase64;
  bool _isScanningDuringRegister = false;

  void _handleFaceRegister(String base64Image) async {
    setState(() {
      _isProcessing = true;
      _showScanner = false;
    });

    final res = await ApiService.registerFace(
      _emailController.text.trim(),
      base64Image,
    );

    setState(() {
      _isProcessing = false;
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firma facial vinculada con éxito.'),
          backgroundColor: AppColors.acentoVioleta,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'No se pudo vincular la firma facial.'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
    }

    _goToSuccessPage();
  }

  void _goToSuccessPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SuccessPage()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleRegisterSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      final res = await ApiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        faceImage: _capturedFaceBase64,
      );

      setState(() {
        _isProcessing = false;
      });

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Código encolado. Abre el Buzón Cuántico.'),
            backgroundColor: AppColors.acentoVioleta,
          ),
        );
        setState(() {
          _showVerification = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Ocurrió un error en el registro.'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  void _handleVerifySubmit() async {
    if (_verifyFormKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      final res = await ApiService.verify(
        _emailController.text.trim(),
        _codeController.text.trim(),
      );

      setState(() {
        _isProcessing = false;
      });

      if (res['success'] == true) {
        if (_capturedFaceBase64 != null) {
          _goToSuccessPage();
        } else {
          setState(() {
            _showVerification = false;
            _showFaceLinkPrompt = true;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Código incorrecto.'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
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
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textoSecundario,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_showVerification) {
                        setState(() {
                          _showVerification = false;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    tooltip: 'Volver',
                  ),
                ),
              ),

              // Central Form Card
              Container(
                constraints: const BoxConstraints(maxWidth: 460),
                child: GlowCard(
                  animateFloating: false,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isScanningDuringRegister
                        ? FaceScannerWidget(
                            title: 'ESCANEAR ROSTRO REGISTRO',
                            onCancel: () => setState(() => _isScanningDuringRegister = false),
                            onCapture: (base64) => setState(() {
                              _capturedFaceBase64 = base64;
                              _isScanningDuringRegister = false;
                            }),
                          )
                        : _showScanner
                            ? FaceScannerWidget(
                                title: 'REGISTRO BIOMÉTRICO FACIAL',
                                onCancel: _goToSuccessPage,
                                onCapture: _handleFaceRegister,
                              )
                            : _showFaceLinkPrompt
                                ? _buildFaceLinkPrompt()
                                : _showVerification 
                                    ? _buildVerificationForm() 
                                    : _buildRegistrationForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'REGISTRO DE IDENTIDAD',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea tus llaves criptográficas de acceso',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 36),

          CustomTextField(
            labelText: 'Nombre de Registro',
            prefixIcon: Icons.badge_outlined,
            controller: _nameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu nombre.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            labelText: 'Email Cuántico',
            prefixIcon: Icons.alternate_email_rounded,
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
          const SizedBox(height: 20),
          CustomTextField(
            labelText: 'Código de Acceso (Password)',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            controller: _passwordController,
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
          const SizedBox(height: 24),
          _buildFaceRegisterSection(),
          const SizedBox(height: 36),

          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.acentoMagenta),
            )
          else
            FuturisticButton(
              text: 'Registrarse',
              icon: Icons.fingerprint_rounded,
              onPressed: _handleRegisterSubmit,
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Form(
      key: _verifyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'VERIFICACIÓN DE NODO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoPrincipal,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el código enviado a ${_emailController.text}.\nConsúltalo en el Buzón Cuántico flotante.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),

          CustomTextField(
            labelText: 'Código Cuántico (6 dígitos)',
            prefixIcon: Icons.pin_rounded,
            controller: _codeController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el código de activación.';
              }
              if (value.trim().length != 6) {
                return 'Debe ser de 6 dígitos.';
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
              text: 'Activar Cuenta',
              icon: Icons.offline_bolt_rounded,
              onPressed: _handleVerifySubmit,
            ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() {
                _showVerification = false;
                _codeController.clear();
              });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.textoSecundario),
            child: const Text('Volver al registro'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceLinkPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.acentoMagenta.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.acentoMagenta.withValues(alpha: 0.2), width: 1.5),
          ),
          child: const Icon(
            Icons.face_retouching_natural_rounded,
            size: 50,
            color: AppColors.acentoMagenta,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'VINCULAR ROSTRO',
          style: TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '¿Deseas registrar tu biometría facial ahora? Esto te permitirá ingresar al sistema de forma instantánea sin escribir contraseñas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        FuturisticButton(
          text: 'Vincular Rostro',
          icon: Icons.face_rounded,
          onPressed: () {
            setState(() {
              _showScanner = true;
              _showFaceLinkPrompt = false;
            });
          },
          width: double.infinity,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _goToSuccessPage,
          style: TextButton.styleFrom(foregroundColor: AppColors.textoSecundario),
          child: const Text('Omitir por ahora'),
        ),
      ],
    );
  }

  Widget _buildFaceRegisterSection() {
    if (_capturedFaceBase64 != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.acentoVioleta.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.acentoVioleta.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROSTRO REGISTRADO',
                    style: TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Firma facial vinculada para el login instantáneo.',
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.acentoMagenta,
                size: 20,
              ),
              tooltip: 'Volver a escanear',
              onPressed: () {
                setState(() {
                  _isScanningDuringRegister = true;
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.acentoMagenta.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.acentoMagenta.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.face_retouching_natural_rounded,
            color: AppColors.acentoMagenta.withValues(alpha: 0.7),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIOMETRÍA FACIAL (RECOMENDADO)',
                  style: TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Inicia sesión sin contraseña usando tu rostro.',
                  style: TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FuturisticButton(
            text: 'Escanear',
            icon: Icons.camera_alt_outlined,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onPressed: () {
              setState(() {
                _isScanningDuringRegister = true;
              });
            },
          ),
        ],
      ),
    );
  }
}
