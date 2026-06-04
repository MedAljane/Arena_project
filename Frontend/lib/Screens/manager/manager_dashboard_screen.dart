import 'package:Arena/models/models.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/Screens/manager/campus/create_campus_screen.dart';
import 'package:Arena/Screens/manager/campus/pending_reservations_screen.dart';
import 'package:Arena/Screens/manager/manager_ai_screen.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int  _employeeCount  = 0;
  bool _empLoading     = true;
  int  _pendingCount   = 0;

  @override
  void initState() {
    super.initState();
    context.read<CampusProvider>().loadMine(context.read<CampusService>());
    _fetchEmployees();
    _fetchPendingCount();
  }

  Future<void> _fetchEmployees() async {
    try {
      final employees = await context.read<EmployeeService>().getManagerEmployees();
      if (mounted) setState(() { _employeeCount = employees.length; _empLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _empLoading = false);
    }
  }

  Future<void> _fetchPendingCount() async {
    try {
      final pending = await context.read<ReservationService>().getPendingReservations();
      if (mounted) setState(() => _pendingCount = pending.length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user    = context.watch<AuthProvider>();
    final campuses = context.watch<CampusProvider>();
    final campus   = campuses.myCampus;
    final hPad    = MediaQuery.of(context).size.width * 0.052;

    // Populate ManagerProvider from campus if not already done.
    if (campus != null) {
      context.read<ManagerProvider>().setFromCampus(campus);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: campuses.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
            : RefreshIndicator(
                color: AppColors.neonGreen,
                onRefresh: () async {
                  final campusSvc = context.read<CampusService>();
                  await context.read<CampusProvider>().refreshMine(campusSvc);
                  _fetchEmployees();
                  _fetchPendingCount();
                },
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color.fromRGBO(46, 204, 113, 0.12),
                          child: Text(user.avatarInitials,
                              style: GoogleFonts.montserrat(
                                  color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Manager Portal',
                                  style: GoogleFonts.inter(
                                      color: AppColors.neonGreen, fontSize: 11,
                                      fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                              Text(user.name,
                                  style: GoogleFonts.montserrat(
                                      color: AppColors.textPrimary,
                                      fontSize: 20, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => user.markNotificationsRead(),
                            child: const SizedBox(
                              width: 46, height: 46,
                              child: Center(child: FaIcon(FontAwesomeIcons.bell,
                                  color: AppColors.textPrimary, size: 18)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // ── Stats ────────────────────────────────────────────────
                    Row(
                      children: [
                        _StatCard(
                          label: 'Terrains',
                          value: '${campus?.nbTerrains ?? 0}',
                          icon: FontAwesomeIcons.trophy,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Employees',
                          value: _empLoading ? '—' : '$_employeeCount',
                          icon: FontAwesomeIcons.users,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Campus',
                          value: campus != null ? '1' : '0',
                          icon: FontAwesomeIcons.building,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Pending requests banner ───────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const PendingReservationsScreen()),
                        );
                        _fetchPendingCount();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _pendingCount > 0
                              ? const Color.fromRGBO(255, 193, 7, 0.10)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _pendingCount > 0
                                ? const Color.fromRGBO(255, 193, 7, 0.5)
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: _pendingCount > 0
                                    ? const Color.fromRGBO(255, 193, 7, 0.15)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.calendarCheck,
                                  color: _pendingCount > 0
                                      ? const Color(0xFFFFC107)
                                      : AppColors.textSecondary,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pending Requests',
                                      style: GoogleFonts.inter(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pendingCount > 0
                                        ? '$_pendingCount reservation${_pendingCount > 1 ? 's' : ''} awaiting approval'
                                        : 'No pending reservations',
                                    style: GoogleFonts.inter(
                                        color: _pendingCount > 0
                                            ? const Color(0xFFFFC107)
                                            : AppColors.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (_pendingCount > 0)
                              Container(
                                width: 24, height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFC107),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('$_pendingCount',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800)),
                                ),
                              )
                            else
                              const FaIcon(FontAwesomeIcons.chevronRight,
                                  color: AppColors.textSecondary, size: 11),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── AI Assistant card ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ManagerAiScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(1, 22, 71, 0.8),
                              Color.fromRGBO(38, 49, 77, 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end:   Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.neonGreen
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color:        const Color.fromRGBO(
                                    46, 204, 113, 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: FaIcon(FontAwesomeIcons.robot,
                                    color: AppColors.neonGreen, size: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(text: TextSpan(children: [
                                  TextSpan(text: 'Manager ',
                                      style: GoogleFonts.inter(
                                          color:      AppColors.textPrimary,
                                          fontSize:   13,
                                          fontWeight: FontWeight.w600)),
                                  TextSpan(text: 'AI',
                                      style: GoogleFonts.inter(
                                          color:      AppColors.neonGreen,
                                          fontSize:   13,
                                          fontWeight: FontWeight.w700)),
                                ])),
                                const SizedBox(height: 2),
                                Text(
                                  'Delegate scheduling & admin tasks',
                                  style: GoogleFonts.inter(
                                      color:    AppColors.textSecondary,
                                      fontSize: 11),
                                ),
                              ],
                            )),
                            const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare,
                                color: AppColors.neonGreen, size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ── My Campus card ────────────────────────────────────────
                    _SectionLabel('My Campus'),
                    const SizedBox(height: 12),
                    if (campus != null)
                      _CampusCard(campus: campus)
                    else
                      _NoDataCard(message: 'No campus assigned yet.'),
                    const SizedBox(height: 26),

                    // ── Quick Actions ─────────────────────────────────────────
                    _SectionLabel('Quick Actions'),
                    const SizedBox(height: 12),
                    _QuickAction(
                      icon:  FontAwesomeIcons.buildingCircleCheck,
                      label: 'New Campus',
                      onTap: () async {
                        final campusProv = context.read<CampusProvider>();
                        final campusSvc  = context.read<CampusService>();
                        final created    = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateCampusScreen()),
                        );
                        if (created == true && mounted) {
                          campusProv.refreshMine(campusSvc);
                        }
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.montserrat(
          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700));
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final dynamic icon;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              FaIcon(icon, color: AppColors.neonGreen, size: 18),
              const SizedBox(height: 8),
              Text(value,
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.campus});
  final Campus campus;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromRGBO(46, 204, 113, 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(46, 204, 113, 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: FaIcon(FontAwesomeIcons.building,
                  color: AppColors.neonGreen, size: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campus.name,
                      style: GoogleFonts.montserrat(
                          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${campus.nbTerrains} terrains · ${campus.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const FaIcon(FontAwesomeIcons.chevronRight, color: AppColors.textSecondary, size: 11),
          ],
        ),
      );
}

class _NoDataCard extends StatelessWidget {
  const _NoDataCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(message, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});
  final dynamic icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: onTap != null ? AppColors.surface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                FaIcon(icon, color: AppColors.neonGreen, size: 20),
                const SizedBox(height: 8),
                Text(label,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}
