import 'package:Arena/models/models.dart';
import 'package:Arena/providers/auth_provider.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});
  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _totalReservations   = 0;
  int _pendingReservations = 0;
  int _confirmedCount      = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final list = await context.read<ReservationService>().getEmployeeReservations();
      if (mounted) {
        setState(() {
          _totalReservations   = list.length;
          _pendingReservations = list.where((r) => r.statu == ReservationStatus.pending).length;
          _confirmedCount      = list.where((r) => r.statu == ReservationStatus.confirmed).length;
          _loading             = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>();
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neonGreen,
          onRefresh: _fetch,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color.fromRGBO(46, 204, 113, 0.12),
                      child: Text(user.avatarInitials,
                          style: GoogleFonts.montserrat(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Employee Portal',
                              style: GoogleFonts.inter(
                                  color: AppColors.neonGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2)),
                          Text(user.name,
                              style: GoogleFonts.montserrat(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Stats ────────────────────────────────────────────────
                Text('My Terrain Stats',
                    style: GoogleFonts.montserrat(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatCard(
                      label: 'Total',
                      value: _loading ? '—' : '$_totalReservations',
                      icon:  FontAwesomeIcons.calendarDays,
                      color: AppColors.neonGreen,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Pending',
                      value: _loading ? '—' : '$_pendingReservations',
                      icon:  FontAwesomeIcons.clock,
                      color: const Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Confirmed',
                      value: _loading ? '—' : '$_confirmedCount',
                      icon:  FontAwesomeIcons.circleCheck,
                      color: AppColors.neonGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Info card ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:        AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color.fromRGBO(46, 204, 113, 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color:        const Color.fromRGBO(46, 204, 113, 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.trophy,
                              color: AppColors.neonGreen, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Role',
                                style: GoogleFonts.montserrat(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(
                              'You manage your assigned terrain. '
                              'Check the Reservations tab to see all bookings.',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String  label;
  final String  value;
  final dynamic icon;
  final Color   color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              FaIcon(icon, color: color, size: 18),
              const SizedBox(height: 8),
              Text(value,
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      );
}
