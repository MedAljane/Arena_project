import 'package:Arena/Screens/player/player_shell.dart';
import 'package:Arena/Screens/shared/login_screen.dart';
import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/providers/auth_provider.dart';
import 'package:Arena/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _loading = false;
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    final username = _usernameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final result = await context.read<AuthService>().register(
        RegisterRequest(username: username, email: email, password: password),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().setSession(result, api);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlayerShell()));
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
              Center(child: Image.asset('assets/arena_logo_1.png', width: 210, height: 210, fit: BoxFit.contain)),
              Text('Create Account',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 32, color: Colors.white)),
              const SizedBox(height: 20),
              _label('Username'),
              const SizedBox(height: 4),
              _inputField(controller: _usernameController, hint: 'yourname', keyboardType: TextInputType.name),
              const SizedBox(height: 13),
              _label('Email Address'),
              const SizedBox(height: 4),
              _inputField(controller: _emailController, hint: 'username@mail.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 13),
              _label('Password'),
              const SizedBox(height: 4),
              _passwordField(),
              const SizedBox(height: 27),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                  : _greenButton(label: 'SIGN UP', onTap: _onSignup),
              const SizedBox(height: 13),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: const Color(0xFFA1A1A1)),
                    children: [
                      const TextSpan(text: 'Already have an account?\n'),
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(color: Color(0xFF2ECC71)),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
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
