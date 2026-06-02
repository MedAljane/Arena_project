import 'package:Arena/Screens/shared/change_password_screen.dart';
import 'package:Arena/Screens/shared/login_screen.dart';
import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/providers/auth_provider.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>();
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile',
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),

              // ── Avatar ──────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              const Color.fromRGBO(46, 204, 113, 0.15),
                          child: Text(user.avatarInitials,
                              style: GoogleFonts.montserrat(
                                  color: AppColors.neonGreen,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:        const Color.fromRGBO(46, 204, 113, 0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.neonGreen
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text('Employee',
                              style: GoogleFonts.inter(
                                  color:      AppColors.neonGreen,
                                  fontSize:   9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: GoogleFonts.montserrat(
                            color:      AppColors.textPrimary,
                            fontSize:   18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Account section ──────────────────────────────────────
              _SectionHeader(label: 'Account'),
              const SizedBox(height: 14),
              _ActionTile(
                icon:  FontAwesomeIcons.lock,
                label: 'Change Password',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen())),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon:  FontAwesomeIcons.bell,
                label: 'Notification Settings',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon:       FontAwesomeIcons.rightFromBracket,
                label:      'Sign Out',
                destructive: true,
                onTap: () async {
                  final api = context.read<ApiService>();
                  try {
                    await context.read<AuthService>().logout();
                  } catch (_) {}
                  if (!context.mounted) return;
                  await context.read<AuthProvider>().clearSession(api);
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.montserrat(
          color:      AppColors.textPrimary,
          fontSize:   15,
          fontWeight: FontWeight.w700));
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final dynamic      icon;
  final String       label;
  final VoidCallback onTap;
  final bool         destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : AppColors.textPrimary;
    return Material(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              FaIcon(icon, color: color, size: 15),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        color:      color,
                        fontSize:   14,
                        fontWeight: FontWeight.w500)),
              ),
              FaIcon(FontAwesomeIcons.chevronRight,
                  color: AppColors.textSecondary, size: 11),
            ],
          ),
        ),
      ),
    );
  }
}
