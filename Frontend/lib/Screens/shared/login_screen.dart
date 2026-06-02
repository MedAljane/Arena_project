import 'package:Arena/Screens/employee/employee_shell.dart';
import 'package:Arena/Screens/manager/manager_shell.dart';
import 'package:Arena/Screens/player/player_shell.dart';
import 'package:Arena/Screens/shared/password_reset_screen.dart';
import 'package:Arena/Screens/shared/signup_screen.dart';
import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/providers/auth_provider.dart';
import 'package:Arena/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in both fields.');
      return;
    }

    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final result = await context.read<AuthService>().login(email, password);
      if (!mounted) return;
      await context.read<AuthProvider>().setSession(result, api);
      if (!mounted) return;

      final destination = switch (result.user.userRole) {
        UserRole.manager  => const ManagerShell(),
        UserRole.employee => const EmployeeShell(),
        _                 => const PlayerShell(),
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122553),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 53),
              Center(
                child: Image.asset('assets/arena_logo_1.png', width: 210, height: 210, fit: BoxFit.contain),
              ),
              Center(
                child: Text(
                  'Welcome Back!',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 39),
              _label('Email Address'),
              const SizedBox(height: 4),
              _inputField(controller: _emailController, hint: 'username@mail.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 13),
              _label('Password'),
              const SizedBox(height: 4),
              _passwordField(),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
                  ),
                  child: Text('Forgot Password?',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: const Color(0xFF2ECC71))),
                ),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                  : _greenButton(label: 'LOGIN', onTap: _onLogin),
              const SizedBox(height: 16),
              const SizedBox(height: 19),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: const Color(0xFFA1A1A1)),
                    children: [
                      const TextSpan(text: "Don't have an account yet?\n"),
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(color: Color(0xFF2ECC71)),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupScreen()),
                              ),
                      ),
                      const TextSpan(text: ' now!'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white.withValues(alpha: 0.4)));

  Widget _inputField({required TextEditingController controller, required String hint, TextInputType? keyboardType}) =>
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0x401E1E1E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
            isCollapsed: true,
            border: InputBorder.none,
          ),
        ),
      );

  Widget _passwordField() => Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0x401E1E1E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
          decoration: InputDecoration(
            hintText: '············',
            hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 17),
            isCollapsed: true,
            border: InputBorder.none,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white, size: 24),
            ),
          ),
        ),
      );

  Widget _greenButton({required String label, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2ECC71),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x402ECC71), blurRadius: 15, offset: Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black.withValues(alpha: 0.4))),
        ),
      );
}
