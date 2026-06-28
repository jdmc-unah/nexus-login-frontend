import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';
import 'dart:js' as js;
import '../core/theme/app_colors.dart';
import '../widgets/futuristic_button.dart';

class FaceScannerWidget extends StatefulWidget {
  final Function(String base64Image) onCapture;
  final VoidCallback onCancel;
  final String title;

  const FaceScannerWidget({
    super.key,
    required this.onCapture,
    required this.onCancel,
    this.title = 'ESCÁNER BIOMÉTRICO FACIAL',
  });

  @override
  State<FaceScannerWidget> createState() => _FaceScannerWidgetState();
}

class _FaceScannerWidgetState extends State<FaceScannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _isCameraInitialized = false;
  String _statusMessage = 'INICIALIZANDO FIRMA ÓPTICA...';

  @override
  void initState() {
    super.initState();

    // Laser scan animation
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _setupJavaScript();
    _registerPlatformView();
    _startCamera();
  }

  void _setupJavaScript() {
    // Check if scripts are already injected
    final existingScript = web.document.getElementById('face-scanner-script');
    if (existingScript == null) {
      final script = web.document.createElement('script') as web.HTMLScriptElement;
      script.id = 'face-scanner-script';
      script.text = '''
        window.initFaceCamera = function() {
          console.log("Initializing camera...");
          navigator.mediaDevices.getUserMedia({ 
            video: { 
              facingMode: 'user', 
              width: { ideal: 640 }, 
              height: { ideal: 640 } 
            } 
          })
          .then(stream => {
            window.localFaceStream = stream;
            const video = document.getElementById('face-video-element');
            if (video) {
              video.srcObject = stream;
              video.play().catch(e => console.error("Error playing video:", e));
              window.dispatchEvent(new CustomEvent('camera-initialized-success'));
            }
          })
          .catch(err => {
            console.error("Camera access error:", err);
            window.dispatchEvent(new CustomEvent('camera-initialized-error', { detail: err.message }));
          });
        };

        window.stopFaceCamera = function() {
          if (window.localFaceStream) {
            window.localFaceStream.getTracks().forEach(track => track.stop());
            window.localFaceStream = null;
          }
        };

        window.captureFace = function() {
          const video = document.getElementById('face-video-element');
          if (!video) return '';
          const canvas = document.createElement('canvas');
          canvas.width = video.videoWidth || 640;
          canvas.height = video.videoHeight || 640;
          const ctx = canvas.getContext('2d');
          
          // Draw mirror image
          ctx.translate(canvas.width, 0);
          ctx.scale(-1, 1);
          
          ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
          return canvas.toDataURL('image/jpeg', 0.85);
        };
      ''';
      web.document.body?.appendChild(script);
    }

    // Add listeners for camera events
    web.window.addEventListener('camera-initialized-success', (web.Event event) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'SISTEMA BIOMÉTRICO EN LÍNEA';
        });
      }
    }.toJS);

    web.window.addEventListener('camera-initialized-error', (web.Event event) {
      final customEvent = event as web.CustomEvent;
      final errorMessage = customEvent.detail?.toString() ?? 'Permiso denegado';
      if (mounted) {
        setState(() {
          _statusMessage = 'ERROR DE CÁMARA: $errorMessage';
        });
      }
    }.toJS);
  }

  void _registerPlatformView() {
    ui_web.platformViewRegistry.registerViewFactory(
      'face-scanner-camera',
      (int viewId) {
        final container = web.document.createElement('div') as web.HTMLDivElement;
        container.style.width = '100%';
        container.style.height = '100%';
        container.style.backgroundColor = '#050005';
        container.style.position = 'relative';
        container.style.overflow = 'hidden';

        final video = web.document.createElement('video') as web.HTMLVideoElement;
        video.id = 'face-video-element';
        video.autoplay = true;
        video.setAttribute('autoplay', 'true');
        video.setAttribute('playsinline', 'true');
        video.setAttribute('muted', 'true');
        
        // Mirror the camera preview
        video.style.transform = 'scaleX(-1)';
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'cover';

        container.appendChild(video);
        return container;
      },
    );
  }

  void _startCamera() {
    Future.delayed(const Duration(milliseconds: 300), () {
      js.context.callMethod('initFaceCamera');
    });
  }

  void _stopCamera() {
    js.context.callMethod('stopFaceCamera');
  }

  void _captureImage() {
    if (!_isCameraInitialized) return;
    
    setState(() {
      _statusMessage = 'EXTRAYENDO EMBEDDINGS BIOMÉTRICOS...';
    });

    final String base64 = js.context.callMethod('captureFace') as String;
    if (base64.isNotEmpty) {
      widget.onCapture(base64);
    } else {
      setState(() {
        _statusMessage = 'ERROR AL CAPTURAR FRAME ÓPTICO';
      });
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: AppColors.fondoBase.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.acentoVioleta.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.acentoMagenta.withValues(alpha: 0.15),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  color: AppColors.acentoMagenta,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          // Camera Preview Box
          Container(
            width: 320,
            height: 320,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCameraInitialized 
                    ? AppColors.acentoMagenta.withValues(alpha: 0.5)
                    : Colors.red.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Native HTML Video Element
                  const HtmlElementView(viewType: 'face-scanner-camera'),
                  
                  // Scanning Grid Overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScannerOverlayPainter(),
                    ),
                  ),

                  // Laser scanning line animation
                  if (_isCameraInitialized)
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanAnimation.value * 320 - 1.5,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.acentoMagenta,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.acentoMagenta,
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Mirror loader when initializing
                  if (!_isCameraInitialized)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.acentoMagenta,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Status & Info text
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.acentoVioleta.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage.contains('ERROR') 
                      ? Colors.redAccent 
                      : AppColors.textoSecundario,
                  fontSize: 11,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: AppColors.textoSecundario.withValues(alpha: 0.7),
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FuturisticButton(
                    text: 'ESCANEAR',
                    icon: Icons.face_retouching_natural_rounded,
                    onPressed: _isCameraInitialized ? _captureImage : () {},
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.acentoMagenta.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid
    final double step = 20.0;
    for (double i = step; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = step; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw futuristic corner brackets
    final cornerPaint = Paint()
      ..color = AppColors.acentoMagenta
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double length = 24.0;

    // Top Left Corner
    canvas.drawLine(const Offset(8, 8), Offset(8 + length, 8), cornerPaint);
    canvas.drawLine(const Offset(8, 8), Offset(8, 8 + length), cornerPaint);

    // Top Right Corner
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8 - length, 8), cornerPaint);
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8, 8 + length), cornerPaint);

    // Bottom Left Corner
    canvas.drawLine(Offset(8, size.height - 8), Offset(8 + length, size.height - 8), cornerPaint);
    canvas.drawLine(Offset(8, size.height - 8), Offset(8, size.height - 8 - length), cornerPaint);

    // Bottom Right Corner
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8 - length, size.height - 8), cornerPaint);
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8, size.height - 8 - length), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
