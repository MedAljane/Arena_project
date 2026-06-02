import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _loading = false;
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hideCurrentPw = true;
  bool _hideNewPw     = true;
  bool _hideConfirmPw = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPw   = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      _showMsg('Please fill in all fields.', isError: true);
      return;
    }
    if (newPw != confirm) {
      _showMsg('New passwords do not match.', isError: true);
      return;
    }
    if (newPw.length < 6) {
      _showMsg('New password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().changePassword(
            currentPassword: current,
            newPassword: newPw,
          );
      if (!mounted) return;
      _showMsg('Password changed successfully!');
      Navigator.pop(context);
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
    final hPad = MediaQuery.of(context).size.width * 0.052;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Row(
                children: [
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40, height: 40,
                        child: Center(child: FaIcon(FontAwesomeIcons.arrowLeft,
                            color: AppColors.textPrimary, size: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Change Password',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Fields ─────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                child: Column(
                  children: [
                    _PwField(
                      label: 'Current Password',
                      controller: _currentCtrl,
                      obscure: _hideCurrentPw,
                      onToggle: () => setState(() => _hideCurrentPw = !_hideCurrentPw),
                    ),
                    const SizedBox(height: 16),
                    _PwField(
                      label: 'New Password',
                      controller: _newCtrl,
                      obscure: _hideNewPw,
                      onToggle: () => setState(() => _hideNewPw = !_hideNewPw),
                    ),
                    const SizedBox(height: 16),
                    _PwField(
                      label: 'Confirm New Password',
                      controller: _confirmCtrl,
                      obscure: _hideConfirmPw,
                      onToggle: () => setState(() => _hideConfirmPw = !_hideConfirmPw),
                    ),
                    const SizedBox(height: 32),
                    _loading
                        ? const CircularProgressIndicator(color: AppColors.neonGreen)
                        : SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AppColors.neonGreen,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _submit,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text('UPDATE PASSWORD',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  const _PwField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11.5,
                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromRGBO(46, 204, 113, 0.35)),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                suffixIcon: GestureDetector(
                  onTap: onToggle,
                  child: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
            ),
          ),
        ],
      );
}
