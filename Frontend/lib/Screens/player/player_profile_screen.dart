import 'package:Arena/Screens/player/player_personal_info_screen.dart';
import 'package:Arena/Screens/shared/change_password_screen.dart';
import 'package:Arena/Screens/shared/login_screen.dart';
import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlayerProvider>().load(context.read<PlayerService>());
    context.read<ReservationProvider>().load(context.read<ReservationService>());
  }

  @override
  Widget build(BuildContext context) {
    final user         = context.watch<AuthProvider>();
    final playerProv   = context.watch<PlayerProvider>();
    final reservations = context.watch<ReservationProvider>();
    final hPad         = MediaQuery.of(context).size.width * 0.052;

    final bookingCount = reservations.reservations.length;
    final phone        = playerProv.phone ?? user.phone;
    final address      = playerProv.address ?? user.location;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neonGreen,
          onRefresh: () async {
            final playerSvc      = context.read<PlayerService>();
            final reservationSvc = context.read<ReservationService>();
            await Future.wait([
              context.read<PlayerProvider>().refresh(playerSvc),
              context.read<ReservationProvider>().refresh(reservationSvc),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile',
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),

              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color.fromRGBO(46, 204, 113, 0.15),
                      child: Text(user.avatarInitials,
                          style: GoogleFonts.montserrat(
                              color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 30)),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(phone,
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(address,
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  _StatChip(
                    label: 'Bookings',
                    value: reservations.isLoading ? '…' : '$bookingCount',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Upcoming',
                    value: reservations.isLoading
                        ? '…'
                        : '${reservations.upcoming.length}',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Cancelled',
                    value: reservations.isLoading
                        ? '…'
                        : '${reservations.cancelled.length}',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              _SectionHeader(label: 'Personal Info'),
              const SizedBox(height: 14),
              _ActionTile(
                icon: FontAwesomeIcons.user,
                label: 'Personal Information',
                subtitle: user.name,
                onTap: () async {
                  final playerProv = context.read<PlayerProvider>();
                  final playerSvc  = context.read<PlayerService>();
                  final updated    = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PlayerPersonalInfoScreen()),
                  );
                  if (updated == true && mounted) playerProv.refresh(playerSvc);
                },
              ),
              const SizedBox(height: 28),

              _SectionHeader(label: 'Account'),
              const SizedBox(height: 14),
              _ActionTile(
                icon: FontAwesomeIcons.lock,
                label: 'Change Password',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              ),
              const SizedBox(height: 10),
              _ActionTile(icon: FontAwesomeIcons.bell,              label: 'Notification Settings', onTap: () {}),
              const SizedBox(height: 10),
              _ActionTile(icon: FontAwesomeIcons.shieldHalved,      label: 'Privacy & Security',    onTap: () {}),
              const SizedBox(height: 10),
              _ActionTile(
                icon: FontAwesomeIcons.rightFromBracket,
                label: 'Sign Out',
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
          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2));
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF282828)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: GoogleFonts.montserrat(
                      color: AppColors.neonGreen, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11.5)),
            ],
          ),
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });
  final dynamic icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : AppColors.textPrimary;
    return Material(
      color: AppColors.surface,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.chevronRight, color: AppColors.textSecondary, size: 11),
            ],
          ),
        ),
      ),
    );
  }
}
