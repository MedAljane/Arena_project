import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent    = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMsg('Please enter your email address.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().forgotPassword(email);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } on AuthException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (e) {
      _showMsg('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              color: isError ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.redAccent : AppColors.neonGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122553),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('← Back to Login',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 20,
                        color: const Color(0xFF2ECC71))),
              ),
              const SizedBox(height: 100),

              if (_sent) ...[
                // ── Success state ───────────────────────────────────────
                const Center(
                  child: Icon(Icons.mark_email_read_rounded,
                      color: Color(0xFF2ECC71), size: 64),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Reset link sent!\nCheck your email inbox.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 20,
                        color: Colors.white, height: 1.4),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _emailController.text.trim(),
                    style: GoogleFonts.inter(
                        color: const Color(0xFF2ECC71), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => setState(() => _sent = false),
                  child: Center(
                    child: Text('Resend email',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              ] else ...[
                // ── Request form ────────────────────────────────────────
                const Center(
                  child: Icon(Icons.lock_open_rounded,
                      color: Color(0xFF2ECC71), size: 64),
                ),
                const SizedBox(height: 13),
                Center(
                  child: Text(
                    'Enter your email below\nand we\'ll send you a reset link.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 20,
                        color: Colors.white, height: 1.22),
                  ),
                ),
                const SizedBox(height: 55),
                Text('Email Address',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 4),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0x401E1E1E),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.4)),
                    decoration: InputDecoration(
                      hintText: 'username@mail.com',
                      hintStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.4)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 17, vertical: 18),
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                    : GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Color(0x402ECC71),
                                  blurRadius: 15, offset: Offset(0, 4)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text('SEND RESET LINK',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700, fontSize: 16,
                                  color: Colors.black.withValues(alpha: 0.6))),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
