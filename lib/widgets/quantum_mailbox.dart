import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/theme/app_colors.dart';

class QuantumMailbox extends StatefulWidget {
  const QuantumMailbox({super.key});

  @override
  State<QuantumMailbox> createState() => _QuantumMailboxState();
}

class _QuantumMailboxState extends State<QuantumMailbox> {
  bool _isOpen = false;
  List<dynamic> _emails = [];
  Timer? _timer;
  int _unreadCount = 0;
  Map<String, dynamic>? _selectedEmail;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
    // Poll inbox every 3 seconds to get simulated emails
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchInbox());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchInbox() async {
    final inbox = await ApiService.fetchInbox();
    if (mounted) {
      setState(() {
        if (inbox.length > _emails.length) {
          _unreadCount += (inbox.length - _emails.length);
        }
        _emails = inbox;
      });
    }
  }

  void _toggleOpen() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _unreadCount = 0;
        _selectedEmail = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Positioned(
      bottom: 24,
      right: isDesktop ? 24 : 12,
      child: _isOpen ? _buildMailboxPanel() : _buildMailboxFab(),
    );
  }

  Widget _buildMailboxFab() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleOpen,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.acentoVioleta, AppColors.acentoMagenta],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.acentoMagenta.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.white,
                size: 28,
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.errorNeon,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMailboxPanel() {
    return Container(
      width: 340,
      height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.25),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              border: Border.all(
                color: AppColors.acentoMagenta.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Panel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.acentoVioleta.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.terminal_rounded,
                        color: AppColors.acentoMagenta,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BUZÓN CUÁNTICO (TEST)',
                        style: TextStyle(
                          color: AppColors.textoPrincipal,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textoSecundario),
                        onPressed: _toggleOpen,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Contents
                Expanded(
                  child: _selectedEmail != null ? _buildMailDetail() : _buildMailList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMailList() {
    if (_emails.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline_rounded, color: AppColors.textoSecundario, size: 40),
              SizedBox(height: 12),
              Text(
                'Bandeja vacía.\nRegistra o recupera una cuenta desde la interfaz y el correo simulado aparecerá aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _emails.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.acentoVioleta.withValues(alpha: 0.15)),
      itemBuilder: (context, index) {
        final email = _emails[index];
        return _MailTile(
          email: email,
          onTap: () {
            setState(() {
              _selectedEmail = email;
            });
          },
        );
      },
    );
  }

  Widget _buildMailDetail() {
    final email = _selectedEmail!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textoSecundario),
                onPressed: () {
                  setState(() {
                    _selectedEmail = null;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Volver a la bandeja',
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            email['subject'].toString().toUpperCase(),
            style: const TextStyle(
              color: AppColors.acentoMagenta,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para: ${email['to']}',
            style: const TextStyle(color: AppColors.textoSecundario, fontSize: 11),
          ),
          Text(
            'Hora: ${email['timestamp']}',
            style: const TextStyle(color: AppColors.textoSecundario, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.acentoVioleta.withValues(alpha: 0.1)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  email['body'],
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MailTile extends StatefulWidget {
  final Map<String, dynamic> email;
  final VoidCallback onTap;

  const _MailTile({required this.email, required this.onTap});

  @override
  State<_MailTile> createState() => _MailTileState();
}

class _MailTileState extends State<_MailTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.04 : 0.01),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.email['subject'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _isHovered ? AppColors.acentoMagenta : AppColors.textoPrincipal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.email['timestamp'],
                    style: const TextStyle(color: AppColors.textoSecundario, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Para: ${widget.email['to']}',
                style: const TextStyle(color: AppColors.textoSecundario, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email['body'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textoSecundario.withValues(alpha: 0.65), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
