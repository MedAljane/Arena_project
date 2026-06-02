import 'package:Arena/Screens/shared/onboarding_screen.dart';
import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/enums.dart';
import 'package:Arena/providers/auth_provider.dart';
import 'package:Arena/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Show splash for at least 1.5 s while we attempt session restore.
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      context.read<AuthProvider>().tryRestoreSession(
            context.read<ApiService>(),
            context.read<AuthService>(),
          ),
    ]);

    if (!mounted) return;

    final role = results[1] as UserRole?;

    if (role == UserRole.manager) {
      Navigator.pushReplacementNamed(context, '/manager');
    } else if (role == UserRole.employee) {
      Navigator.pushReplacementNamed(context, '/employee');
    } else if (role == UserRole.player) {
      Navigator.pushReplacementNamed(context, '/player');
    } else {
      // No valid saved session → show onboarding.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xFF122553),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/arena_logo_1.png', height: 300, width: 300),
            const SizedBox(height: 25),
            const Text(
              "Let's get you back on the Arena.",
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFF2ECC71),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
