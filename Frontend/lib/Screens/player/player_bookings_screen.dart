import 'package:Arena/models/models.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlayerBookingsScreen extends StatefulWidget {
  const PlayerBookingsScreen({super.key});

  @override
  State<PlayerBookingsScreen> createState() => _PlayerBookingsScreenState();
}

class _PlayerBookingsScreenState extends State<PlayerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load if not already; provider is shared with the dashboard.
    context.read<ReservationProvider>().load(context.read<ReservationService>());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      context.read<ReservationProvider>().refresh(context.read<ReservationService>());

  Future<void> _cancelReservation(Reservation r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Booking',
            style: GoogleFonts.montserrat(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Cancel your ${r.terrain?.type.name ?? ''} booking'
          '${r.timeSlot != null ? ' at ${r.timeSlot!.startTime}–${r.timeSlot!.endTime}' : ''}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cancel booking',
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ReservationProvider>().cancel(
            r.id, context.read<ReservationService>());
    } on ServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _openDetail(Reservation r) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BookingDetailSheet(
        reservation: r,
        onCancel: () => _cancelReservation(r),
      ),
    );
    if (changed == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final upcoming  = provider.upcoming;
    final cancelled = provider.cancelled;
    final all       = provider.reservations;
    final hPad      = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('My Bookings',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  if (!provider.isLoading)
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _refresh,
                        child: const SizedBox(
                          width: 46, height: 46,
                          child: Center(child: FaIcon(FontAwesomeIcons.arrowsRotate,
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
                  labelColor: Colors.black,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: 'Upcoming (${upcoming.length})'),
                    const Tab(text: 'All'),
                    Tab(text: 'Cancelled (${cancelled.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.neonGreen))
                  : provider.error != null
                      ? _ErrorView(
                          message: provider.error!,
                          onRetry: _refresh,
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _ReservationList(
                              reservations: upcoming,
                              hPad: hPad,
                              emptyLabel: 'No upcoming bookings',
                              emptyIcon: FontAwesomeIcons.calendarCheck,
                              onRefresh: _refresh,
                              onTap: _openDetail,
                              onCancel: _cancelReservation,
                            ),
                            _ReservationList(
                              reservations: all,
                              hPad: hPad,
                              emptyLabel: 'No reservations yet',
                              emptyIcon: FontAwesomeIcons.calendarXmark,
                              onRefresh: _refresh,
                              onTap: _openDetail,
                              onCancel: _cancelReservation,
                            ),
                            _ReservationList(
                              reservations: cancelled,
                              hPad: hPad,
                              emptyLabel: 'No cancelled bookings',
                              emptyIcon: FontAwesomeIcons.ban,
                              onRefresh: _refresh,
                              onTap: _openDetail,
                              onCancel: _cancelReservation,
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
    required this.emptyIcon,
    required this.onRefresh,
    required this.onTap,
    required this.onCancel,
  });

  final List<Reservation>        reservations;
  final double                   hPad;
  final String                   emptyLabel;
  final dynamic                  emptyIcon;
  final Future<void> Function()  onRefresh;
  final void Function(Reservation) onTap;
  final void Function(Reservation) onCancel;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return RefreshIndicator(
        color: AppColors.neonGreen,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                FaIcon(emptyIcon, color: AppColors.textSecondary, size: 40),
                const SizedBox(height: 14),
                Text(emptyLabel,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 14)),
              ]),
            ),
          ],
        ),
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
        itemBuilder: (_, i) => _BookingCard(
          reservation: reservations[i],
          onTap: () => onTap(reservations[i]),
          onCancel: () => onCancel(reservations[i]),
        ),
      ),
    );
  }
}

// ─── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.reservation,
    required this.onTap,
    required this.onCancel,
  });

  final Reservation    reservation;
  final VoidCallback   onTap;
  final VoidCallback   onCancel;

  static String _fmtSlotDate(TimeSlotSummary? ts) {
    if (ts == null) return '—';
    if (ts.dayOfWeek != null && ts.slotDate != null) {
      final dt = DateTime.tryParse(ts.slotDate!);
      if (dt != null) {
        const m = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
        return '${ts.dayOfWeek!}  ·  ${m[dt.month - 1]} ${dt.day}';
      }
      return '${ts.dayOfWeek!}  ·  ${ts.slotDate!}';
    }
    return '—';
  }

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
    final timeSlot    = r.timeSlot;
    final timeLabel   = timeSlot != null
        ? '${timeSlot.startTime} – ${timeSlot.endTime}'
        : '—';
    final statusColor = _statusColor(r.statu);
    final isCancelled = r.statu == ReservationStatus.cancelled;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row ─────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? AppColors.surfaceVariant
                          : const Color.fromRGBO(46, 204, 113, 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: FaIcon(
                        _terrainIcon(r.terrain?.type),
                        color: isCancelled
                            ? AppColors.textSecondary
                            : AppColors.neonGreen,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sport,
                            style: GoogleFonts.montserrat(
                                color: isCancelled
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text(timeLabel,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.statu.name[0].toUpperCase() +
                          r.statu.name.substring(1),
                      style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),

              // ── Bottom row ──────────────────────────────────────────
              Row(
                children: [
                  _Pill(
                      icon: FontAwesomeIcons.calendarDay,
                      label: _fmtSlotDate(r.timeSlot)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: r.type == ReservationType.urgent
                          ? const Color.fromRGBO(231, 76, 60, 0.12)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.type.name[0].toUpperCase() +
                          r.type.name.substring(1),
                      style: GoogleFonts.inter(
                          color: r.type == ReservationType.urgent
                              ? Colors.redAccent
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  if (!isCancelled)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onCancel,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),

              // ── Notes preview ────────────────────────────────────────
              if (r.notes != null && r.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.noteSticky,
                        color: AppColors.textSecondary, size: 10),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Booking detail sheet ─────────────────────────────────────────────────────

class _BookingDetailSheet extends StatefulWidget {
  const _BookingDetailSheet({
    required this.reservation,
    required this.onCancel,
  });

  final Reservation        reservation;
  final VoidCallback       onCancel;

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  late final TextEditingController _notesCtrl;
  bool _savingNotes = false;
  bool _notesChanged = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.reservation.notes ?? '');
    _notesCtrl.addListener(() {
      final changed = _notesCtrl.text.trim() != (widget.reservation.notes ?? '');
      if (changed != _notesChanged) setState(() => _notesChanged = changed);
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => _savingNotes = true);
    try {
      await context.read<ReservationProvider>().update(
        widget.reservation.id,
        UpdateReservationRequest(notes: _notesCtrl.text.trim()),
        context.read<ReservationService>(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _savingNotes = false);
    }
  }

  static dynamic _terrainIcon(TerrainType? t) => switch (t) {
        TerrainType.Football   => FontAwesomeIcons.futbol,
        TerrainType.Basketball => FontAwesomeIcons.basketball,
        TerrainType.Paddel     => FontAwesomeIcons.tableTennisPaddleBall,
        TerrainType.Tennis     => FontAwesomeIcons.tableTennisPaddleBall,
        _                      => FontAwesomeIcons.trophy,
      };

  static Color _statusColor(ReservationStatus s) => switch (s) {
        ReservationStatus.confirmed => AppColors.neonGreen,
        ReservationStatus.pending   => const Color(0xFFFFC107),
        ReservationStatus.cancelled => Colors.redAccent,
      };

  @override
  Widget build(BuildContext context) {
    final r           = widget.reservation;
    final isCancelled = r.statu == ReservationStatus.cancelled;
    final statusColor = _statusColor(r.statu);
    final timeLabel   = r.timeSlot != null
        ? '${r.timeSlot!.startTime} – ${r.timeSlot!.endTime}'
        : '—';

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title row ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppColors.surfaceVariant
                      : const Color.fromRGBO(46, 204, 113, 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(
                    _terrainIcon(r.terrain?.type),
                    color: isCancelled
                        ? AppColors.textSecondary
                        : AppColors.neonGreen,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.terrain?.type.name ?? 'Booking',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    Text(timeLabel,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.statu.name[0].toUpperCase() + r.statu.name.substring(1),
                  style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Detail rows ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color.fromRGBO(46, 204, 113, 0.2)),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: FontAwesomeIcons.calendarDay,
                  label: 'Scheduled for',
                  value: _BookingCard._fmtSlotDate(r.timeSlot),
                ),
                const Divider(color: AppColors.divider, height: 20),
                _DetailRow(
                  icon: FontAwesomeIcons.clock,
                  label: 'Time',
                  value: timeLabel,
                ),
                const Divider(color: AppColors.divider, height: 20),
                _DetailRow(
                  icon: FontAwesomeIcons.calendarCheck,
                  label: 'Booked on',
                  value: r.bookedAt != null
                      ? _fmtDateTime(r.bookedAt!)
                      : '—',
                ),
                const Divider(color: AppColors.divider, height: 20),
                _DetailRow(
                  icon: FontAwesomeIcons.tag,
                  label: 'Type',
                  value: r.type.name[0].toUpperCase() + r.type.name.substring(1),
                  valueColor: r.type == ReservationType.urgent
                      ? Colors.redAccent
                      : null,
                ),
                if (r.manager != null) ...[
                  const Divider(color: AppColors.divider, height: 20),
                  _DetailRow(
                    icon: FontAwesomeIcons.userTie,
                    label: 'Manager',
                    value: r.manager!.nom ?? 'ID ${r.manager!.id}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Notes ─────────────────────────────────────────────────
          Text('Notes',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isCancelled
                      ? AppColors.divider
                      : const Color.fromRGBO(46, 204, 113, 0.35)),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              readOnly: isCancelled,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: isCancelled
                    ? 'No notes'
                    : 'Add a note for the manager…',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Actions ───────────────────────────────────────────────
          if (!isCancelled)
            Row(
              children: [
                // Cancel booking
                Expanded(
                  child: Material(
                    color: const Color.fromRGBO(231, 76, 60, 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onCancel();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text('Cancel Booking',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ),
                if (_notesChanged) ...[
                  const SizedBox(width: 10),
                  // Save notes
                  Expanded(
                    child: _savingNotes
                        ? const Center(
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  color: AppColors.neonGreen,
                                  strokeWidth: 2),
                            ))
                        : Material(
                            color: AppColors.neonGreen,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _saveNotes,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                child: Text('Save Notes',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  static String _fmtDateTime(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$min';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final dynamic icon;
  final String  label;
  final String  value;
  final Color?  valueColor;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          FaIcon(icon, color: AppColors.neonGreen, size: 12),
          const SizedBox(width: 10),
          Text('$label: ',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final dynamic icon;
  final String  label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: AppColors.textSecondary, size: 11),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}

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
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
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
