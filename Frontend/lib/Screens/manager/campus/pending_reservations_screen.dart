import 'package:Arena/models/models.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PendingReservationsScreen extends StatefulWidget {
  const PendingReservationsScreen({super.key});

  @override
  State<PendingReservationsScreen> createState() =>
      _PendingReservationsScreenState();
}

class _PendingReservationsScreenState
    extends State<PendingReservationsScreen> {
  List<Reservation> _reservations = [];
  bool    _loading = true;
  String? _error;

  // Track which reservations are being actioned (to show per-card spinner).
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await context.read<ReservationService>().getPendingReservations();
      if (mounted) setState(() { _reservations = list; _loading = false; });
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _confirm(Reservation r) async {
    setState(() => _processing.add(r.id));
    try {
      await context.read<ReservationService>().confirmReservation(r.id);
      if (mounted) {
        _showMsg('Reservation confirmed. A chat with the player has been created.');
        _fetch();
      }
    } on ServiceException catch (e) {
      if (mounted) _showMsg(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _processing.remove(r.id));
    }
  }

  Future<void> _deny(Reservation r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Deny Reservation',
            style: GoogleFonts.montserrat(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Deny this booking request? The time slot will be made available again.',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Deny',
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _processing.add(r.id));
    try {
      await context.read<ReservationService>().denyReservation(r.id);
      if (mounted) {
        _showMsg('Reservation denied. Slot is available again.');
        _fetch();
      }
    } on ServiceException catch (e) {
      if (mounted) _showMsg(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _processing.remove(r.id));
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

  static dynamic _iconFor(TerrainType? t) => switch (t) {
        TerrainType.Football   => FontAwesomeIcons.futbol,
        TerrainType.Basketball => FontAwesomeIcons.basketball,
        TerrainType.Paddel     => FontAwesomeIcons.tableTennisPaddleBall,
        TerrainType.Tennis     => FontAwesomeIcons.tableTennisPaddleBall,
        _                      => FontAwesomeIcons.trophy,
      };

  static String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pending Requests',
                            style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        if (!_loading)
                          Text(
                            '${_reservations.length} awaiting your decision',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  if (!_loading)
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _fetch,
                        child: const SizedBox(
                          width: 40, height: 40,
                          child: Center(child: FaIcon(
                              FontAwesomeIcons.arrowsRotate,
                              color: AppColors.textPrimary, size: 14)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 20),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                        color: AppColors.neonGreen))
                  : _error != null
                      ? Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _fetch,
                              child: Text('Retry',
                                  style: GoogleFonts.inter(
                                      color: AppColors.neonGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]))
                      : _reservations.isEmpty
                          ? Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                const FaIcon(FontAwesomeIcons.circleCheck,
                                    color: AppColors.neonGreen, size: 44),
                                const SizedBox(height: 14),
                                Text('All caught up!',
                                    style: GoogleFonts.montserrat(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('No pending reservations.',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ]))
                          : RefreshIndicator(
                              color: AppColors.neonGreen,
                              onRefresh: _fetch,
                              child: ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                    hPad, 0, hPad, 40),
                                itemCount: _reservations.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) {
                                  final r = _reservations[i];
                                  return _PendingCard(
                                    reservation: r,
                                    processing: _processing.contains(r.id),
                                    iconFor: _iconFor,
                                    fmtDate: _fmtDate,
                                    onConfirm: () => _confirm(r),
                                    onDeny:    () => _deny(r),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending reservation card ─────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.reservation,
    required this.processing,
    required this.iconFor,
    required this.fmtDate,
    required this.onConfirm,
    required this.onDeny,
  });

  final Reservation    reservation;
  final bool           processing;
  final dynamic Function(TerrainType?) iconFor;
  final String Function(DateTime?) fmtDate;
  final VoidCallback   onConfirm;
  final VoidCallback   onDeny;

  @override
  Widget build(BuildContext context) {
    final r        = reservation;
    final sport    = r.terrain?.type.name ?? 'Booking';
    final timeSlot = r.timeSlot;
    final timeLabel = timeSlot != null
        ? '${timeSlot.startTime} – ${timeSlot.endTime}'
        : '—';
    final dateLabel = timeSlot?.dayOfWeek != null
        ? '${timeSlot!.dayOfWeek!}  ·  ${timeSlot.slotDate ?? ''}'
        : fmtDate(r.bookedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color.fromRGBO(255, 193, 7, 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 193, 7, 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: FaIcon(iconFor(r.terrain?.type),
                      color: const Color(0xFFFFC107), size: 15),
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
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 193, 7, 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Pending',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFFFC107),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),

          // ── Details ──────────────────────────────────────────────
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.clock,
                  color: AppColors.textSecondary, size: 11),
              const SizedBox(width: 6),
              Text(timeLabel,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 16),
              const FaIcon(FontAwesomeIcons.user,
                  color: AppColors.textSecondary, size: 11),
              const SizedBox(width: 6),
              Text(r.player?.nom ?? 'Player #${r.player?.id ?? '—'}',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          if (r.notes != null && r.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.noteSticky,
                    color: AppColors.textSecondary, size: 11),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(r.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 11)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // ── Actions ──────────────────────────────────────────────
          processing
              ? const Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.neonGreen),
                  ))
              : Row(
                  children: [
                    // Deny
                    Expanded(
                      child: Material(
                        color: const Color.fromRGBO(231, 76, 60, 0.10),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onDeny,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 11),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const FaIcon(FontAwesomeIcons.xmark,
                                    color: Colors.redAccent, size: 12),
                                const SizedBox(width: 6),
                                Text('Deny',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Confirm
                    Expanded(
                      child: Material(
                        color: AppColors.neonGreen,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onConfirm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 11),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const FaIcon(FontAwesomeIcons.check,
                                    color: Colors.black, size: 12),
                                const SizedBox(width: 6),
                                Text('Confirm',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
