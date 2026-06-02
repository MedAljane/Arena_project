import 'package:Arena/models/models.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EmployeeReservationsScreen extends StatefulWidget {
  const EmployeeReservationsScreen({super.key});
  @override
  State<EmployeeReservationsScreen> createState() => _EmployeeReservationsScreenState();
}

class _EmployeeReservationsScreenState extends State<EmployeeReservationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Reservation> _reservations = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await context.read<ReservationService>().getEmployeeReservations();
      if (mounted) setState(() { _reservations = list; _loading = false; });
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Reservation> get _confirmed =>
      _reservations.where((r) => r.statu == ReservationStatus.confirmed).toList();
  List<Reservation> get _pending =>
      _reservations.where((r) => r.statu == ReservationStatus.pending).toList();
  List<Reservation> get _cancelled =>
      _reservations.where((r) => r.statu == ReservationStatus.cancelled).toList();

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Reservations',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                  ),
                  if (!_loading)
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _fetch,
                        child: const SizedBox(
                          width: 46, height: 46,
                          child: Center(child: FaIcon(
                              FontAwesomeIcons.arrowsRotate,
                              color: AppColors.textPrimary, size: 16)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Tabs ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                      color: AppColors.neonGreen,
                      borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  labelColor:           Colors.black,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: 'Confirmed (${_confirmed.length})'),
                    Tab(text: 'Pending (${_pending.length})'),
                    Tab(text: 'Cancelled (${_cancelled.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                        color: AppColors.neonGreen))
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _fetch)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _ReservationList(
                              reservations: _confirmed,
                              hPad:         hPad,
                              emptyLabel:   'No confirmed bookings.',
                              onRefresh:    _fetch,
                            ),
                            _ReservationList(
                              reservations: _pending,
                              hPad:         hPad,
                              emptyLabel:   'No pending bookings.',
                              onRefresh:    _fetch,
                            ),
                            _ReservationList(
                              reservations: _cancelled,
                              hPad:         hPad,
                              emptyLabel:   'No cancelled bookings.',
                              onRefresh:    _fetch,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reservation list ─────────────────────────────────────────────────────────

class _ReservationList extends StatelessWidget {
  const _ReservationList({
    required this.reservations,
    required this.hPad,
    required this.emptyLabel,
    required this.onRefresh,
  });
  final List<Reservation>       reservations;
  final double                  hPad;
  final String                  emptyLabel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return RefreshIndicator(
        color: AppColors.neonGreen,
        onRefresh: onRefresh,
        child: ListView(physics: const AlwaysScrollableScrollPhysics(),
            children: [
          SizedBox(
            height: 250,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const FaIcon(FontAwesomeIcons.calendarXmark,
                    color: AppColors.textSecondary, size: 40),
                const SizedBox(height: 14),
                Text(emptyLabel,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 14)),
              ]),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.neonGreen,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
        itemCount: reservations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ReservationCard(reservation: reservations[i]),
      ),
    );
  }
}

// ─── Reservation card ─────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation});
  final Reservation reservation;

  static Color _statusColor(ReservationStatus s) => switch (s) {
        ReservationStatus.confirmed => AppColors.neonGreen,
        ReservationStatus.pending   => const Color(0xFFFFC107),
        ReservationStatus.cancelled => Colors.redAccent,
      };

  static dynamic _terrainIcon(TerrainType? t) => switch (t) {
        TerrainType.Football   => FontAwesomeIcons.futbol,
        TerrainType.Basketball => FontAwesomeIcons.basketball,
        TerrainType.Paddel     => FontAwesomeIcons.tableTennisPaddleBall,
        TerrainType.Tennis     => FontAwesomeIcons.tableTennisPaddleBall,
        _                      => FontAwesomeIcons.trophy,
      };

  @override
  Widget build(BuildContext context) {
    final r           = reservation;
    final sport       = r.terrain?.type.name ?? 'Booking';
    final slot        = r.timeSlot;
    final timeLabel   = slot != null
        ? '${slot.startTime} – ${slot.endTime}'
        : '—';
    final dateLabel   = slot?.dayOfWeek != null
        ? '${slot!.dayOfWeek!}  ·  ${slot.slotDate ?? ''}'
        : '—';
    final statusColor = _statusColor(r.statu);
    final playerName  = r.player?.nom ?? 'Player #${r.player?.id ?? '—'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        const Color.fromRGBO(46, 204, 113, 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: FaIcon(_terrainIcon(r.terrain?.type),
                      color: AppColors.neonGreen, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sport,
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text(dateLabel,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  r.statu.name[0].toUpperCase() + r.statu.name.substring(1),
                  style: GoogleFonts.inter(
                      color:      statusColor,
                      fontSize:   10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),

          // Details row
          Wrap(spacing: 16, runSpacing: 6, children: [
            _Pill(icon: FontAwesomeIcons.user,      label: playerName),
            _Pill(icon: FontAwesomeIcons.clock,     label: timeLabel),
            if (r.type == ReservationType.urgent)
              _Pill(icon: FontAwesomeIcons.boltLightning, label: 'Urgent',
                  color: Colors.redAccent),
          ]),

          if (r.notes != null && r.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Pill(icon: FontAwesomeIcons.noteSticky, label: r.notes!),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    this.color,
  });
  final dynamic icon;
  final String  label;
  final Color?  color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon,
              size:  11,
              color: color ?? AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color:    color ?? AppColors.textSecondary,
                  fontSize: 12)),
        ],
      );
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String       message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation,
              color: Colors.redAccent, size: 36),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('Retry',
                  style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ]),
      );
}
