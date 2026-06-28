import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/face_scanner_widget.dart';
import '../widgets/glow_card.dart';
import '../widgets/futuristic_button.dart';
import '../widgets/custom_text_field.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'registration_page.dart';
import 'recover_page.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  int _activeTab = 0; // 0 = Iniciar Sesión, 1 = Crear Cuenta
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _isLoggingIn = false;
  bool _showScanner = false;

  void _handleFaceLogin(String base64Image) async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoggingIn = true;
      _showScanner = false;
    });

    final res = await ApiService.loginFace(email, base64Image);

    setState(() {
      _isLoggingIn = false;
    });

    if (res['success'] == true) {
      ApiService.loggedInEmail = res['user']['email'];
      ApiService.loggedInName = res['user']['name'];
      _loginEmailController.clear();
      _loginPasswordController.clear();
      
      Navigator.pushReplacementNamed(context, '/billboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Acceso facial denegado.'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa email y contraseña cuántica.'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    final res = await ApiService.login(email, password);

    setState(() {
      _isLoggingIn = false;
    });

    if (res['success'] == true) {
      ApiService.loggedInEmail = res['user']['email'];
      ApiService.loggedInName = res['user']['name'];
      _loginEmailController.clear();
      _loginPasswordController.clear();
      
      Navigator.pushReplacementNamed(context, '/billboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Acceso denegado.'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Futuristic Header Logo
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.acentoMagenta.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.acentoMagenta.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  size: 40,
                  color: AppColors.acentoMagenta,
                ),
              ),
              // App Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.textoPrincipal, AppColors.textoSecundario],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Text(
                  'ANTIGRAVITY SYSTEM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'MÓDULO DE AUTENTICACIÓN MULTIVERSE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 50),

              // Layout switcher (Desktop Row vs Mobile Column)
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 850;
                  return isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildLeftPortalCard(),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _buildRightPortalCard(context),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildLeftPortalCard(),
                            const SizedBox(height: 32),
                            _buildRightPortalCard(context),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPortalCard() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlowCard(
          animateFloating: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tabs inside the card
              Row(
                children: [
                  Expanded(
                    child: _buildTabHeader(
                      title: 'Iniciar Sesión',
                      isActive: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTabHeader(
                      title: 'Crear Cuenta',
                      isActive: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Dynamic Panel
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _activeTab == 0 ? _buildLoginForm() : _buildRegisterInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabHeader({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.acentoMagenta : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.textoPrincipal : AppColors.textoSecundario,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    if (_showScanner) {
      return FaceScannerWidget(
        title: 'AUTENTICACIÓN ÓPTICA',
        onCancel: () => setState(() => _showScanner = false),
        onCapture: (base64) => _handleFaceLogin(base64),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          labelText: 'Email Cuántico',
          prefixIcon: Icons.alternate_email_rounded,
          controller: _loginEmailController,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          labelText: 'Código de Acceso',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
          controller: _loginPasswordController,
        ),
        const SizedBox(height: 32),
        if (_isLoggingIn)
          const Center(
            child: CircularProgressIndicator(color: AppColors.acentoMagenta),
          )
        else ...[
          FuturisticButton(
            text: 'Conectar portal',
            icon: Icons.login_rounded,
            onPressed: _handleLogin,
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          FuturisticButton(
            text: 'Acceso Facial',
            icon: Icons.face_retouching_natural_rounded,
            onPressed: () {
              final email = _loginEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa tu Email Cuántico primero para iniciar escaneo.'),
                    backgroundColor: AppColors.errorNeon,
                  ),
                );
                return;
              }
              setState(() => _showScanner = true);
            },
            isSecondary: true,
            width: double.infinity,
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.acentoMagenta.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.acentoMagenta.withValues(alpha: 0.2), width: 1.5),
          ),
          child: const Icon(
            Icons.person_add_outlined,
            size: 50,
            color: AppColors.acentoMagenta,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Inicializa tu firma criptográfica en el sistema y comienza el viaje en la red segura.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        FuturisticButton(
          text: 'Registrarse',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegistrationPage()),
            );
          },
          isSecondary: false,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildRightPortalCard(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlowCard(
          animateFloating: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.acentoVioleta.withValues(alpha: 0.06),
                  border: Border.all(color: AppColors.acentoVioleta.withValues(alpha: 0.2), width: 1.5),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 50,
                  color: AppColors.acentoVioleta,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'RECUPERAR ACCESO',
                style: TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Restaura tus credenciales perdidas u olvidadas a través de nuestro protocolo cuántico.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              FuturisticButton(
                text: 'Recuperar',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecoverPage()),
                  );
                },
                isSecondary: true,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
