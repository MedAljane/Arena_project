import 'package:Arena/admin/providers/admin_auth_provider.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _loading      = false;
  bool  _obscure      = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AdminAuthProvider>().login(email, password);
      // go_router's refreshListenable redirects automatically
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;

    return Scaffold(
      backgroundColor: ext.bg,
      body: Stack(
        children: [
          // ── Background grid ────────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(ext.border)),
          ),

          // ── Center card ────────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color:        AdminColors.indigo,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AdminColors.indigo.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text('Admin Portal',
                        style: TextStyle(
                            color:      ext.text,
                            fontSize:   28,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Sign in to manage your platform',
                        style: TextStyle(color: ext.muted, fontSize: 14)),
                    const SizedBox(height: 32),

                    // Card
                    Container(
                      padding:      const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color:        ext.card,
                        borderRadius: BorderRadius.circular(20),
                        border:       Border.all(color: ext.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AdminColors.danger
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AdminColors.danger
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: AdminColors.danger, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: AdminColors.danger,
                                          fontSize: 13)),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 16),
                          ],

                          _label('Email address', ext),
                          const SizedBox(height: 6),
                          TextField(
                            controller:   _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            onSubmitted:  (_) => _submit(),
                            style:        TextStyle(color: ext.text, fontSize: 14),
                            decoration: _inputDec(
                                'admin@example.com', ext),
                          ),
                          const SizedBox(height: 16),

                          _label('Password', ext),
                          const SizedBox(height: 6),
                          TextField(
                            controller:  _passwordCtrl,
                            obscureText: _obscure,
                            onSubmitted: (_) => _submit(),
                            style:       TextStyle(color: ext.text, fontSize: 14),
                            decoration: _inputDec('••••••••', ext).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: ext.subtle, size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.indigo,
                                disabledBackgroundColor:
                                    AdminColors.indigo.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Sign in',
                                      style: TextStyle(
                                          color:      Colors.white,
                                          fontSize:   15,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Admin access only · Unauthorized use is prohibited',
                        style: TextStyle(color: ext.subtle, fontSize: 12),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, AdminExt ext) => Text(text,
      style: TextStyle(
          color:      ext.muted,
          fontSize:   13,
          fontWeight: FontWeight.w500));

  InputDecoration _inputDec(String hint, AdminExt ext) => InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(color: ext.subtle, fontSize: 14),
        filled:    true,
        fillColor: ext.input,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide(color: ext.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide(color: ext.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AdminColors.indigo, width: 1.5)),
      );
}

// ─── Background grid painter ──────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
