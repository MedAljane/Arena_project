import 'package:Arena/models/models.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ─── Data holder ─────────────────────────────────────────────────────────────

class _AgendaData {
  final WeekAgenda      agenda;
  bool                  weekExpanded;
  final Map<int, bool>  dayExpanded;

  // cachedSlots removed — TimeSlotProvider is the single cache now.

  _AgendaData({required this.agenda})
      : weekExpanded = false,
        dayExpanded  = {};
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TerrainAvailabilityScreen extends StatefulWidget {
  final Terrain terrain;
  final Campus  campus;

  const TerrainAvailabilityScreen({
    super.key,
    required this.terrain,
    required this.campus,
  });

  @override
  State<TerrainAvailabilityScreen> createState() =>
      _TerrainAvailabilityScreenState();
}

class _TerrainAvailabilityScreenState
    extends State<TerrainAvailabilityScreen> {
  List<_AgendaData> _agendas = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ── Initial load: agenda + busyness (no slots) ─────────────────────────────

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    final svc = context.read<WeekAgendaService>();
    try {
      final published = widget.terrain.weekAgenda
          .where((a) => a.statu == WeekAgendaStatus.Published)
          .toList();

      if (published.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Busyness is stored on the model — one call per agenda, no extra calls.
      final agendas = await Future.wait(
        published.map((s) => svc.getWeekAgenda(s.id)),
      );

      if (mounted) {
        setState(() {
          _agendas = agendas.map((ag) => _AgendaData(agenda: ag)).toList();
          _loading = false;
        });
      }
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  // ── Lazy slot loading — delegates entirely to TimeSlotProvider ──────────────

  void _loadSlots(int dayPlanId) {
    context.read<TimeSlotProvider>().load(
          dayPlanId, context.read<WeekAgendaService>());
  }

  // ── Reservation booking ────────────────────────────────────────────────────

  void _openReservation(TimeSlot slot, DayPlan dayPlan) async {
    final slotProv = context.read<TimeSlotProvider>();
    final booked   = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReservationSheet(
        slot:    slot,
        dayPlan: dayPlan,
        terrain: widget.terrain,
        campus:  widget.campus,
      ),
    );
    if (booked == true && mounted) {
      // Invalidate all cached slots so every day shows updated availability.
      slotProv.invalidateAll();
      _fetchAll();
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static dynamic _terrainIcon(TerrainType t) => switch (t) {
        TerrainType.Football   => FontAwesomeIcons.futbol,
        TerrainType.Basketball => FontAwesomeIcons.basketball,
        TerrainType.Paddel     => FontAwesomeIcons.tableTennisPaddleBall,
        TerrainType.Tennis     => FontAwesomeIcons.tableTennisPaddleBall,
      };

  String _fmtWeek(String start) {
    final dt = DateTime.tryParse(start);
    if (dt == null) return start;
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    final end = dt.add(const Duration(days: 6));
    return '${m[dt.month-1]} ${dt.day} – ${m[end.month-1]} ${end.day}';
  }

  static Color _busyColor(double r) {
    if (r < 0.3)  return const Color(0xFF2ECC71);
    if (r < 0.65) return const Color(0xFFFFC107);
    return Colors.redAccent;
  }

  static String _busyLabel(double r) {
    if (r < 0.3)  return 'Free';
    if (r < 0.65) return 'Moderate';
    return 'Busy';
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;
    final t    = widget.terrain;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
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
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(46, 204, 113, 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: FaIcon(_terrainIcon(t.type),
                          color: AppColors.neonGreen, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t.type.name} — ${widget.campus.name}',
                            style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        Text('Available schedules',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 20),

            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                        color: AppColors.neonGreen))
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: () {
                          setState(() { _loading = true; _error = null; });
                          _fetchAll();
                        })
                      : _agendas.isEmpty
                          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const FaIcon(FontAwesomeIcons.calendarXmark,
                                  color: AppColors.textSecondary, size: 40),
                              const SizedBox(height: 14),
                              Text('No schedules published yet.',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Check back later.',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary, fontSize: 12)),
                            ]))
                          : RefreshIndicator(
                              color: AppColors.neonGreen,
                              onRefresh: _fetchAll,
                              child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                              itemCount: _agendas.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final d = _agendas[i];
                                return _WeekSection(
                                  data:         d,
                                  fmtWeek:      _fmtWeek,
                                  busyColor:    _busyColor,
                                  busyLabel:    _busyLabel,
                                  onToggleWeek: () => setState(() =>
                                      d.weekExpanded = !d.weekExpanded),
                                  onToggleDay:  (dpId) {
                                    final nowOpen = !(d.dayExpanded[dpId] ?? false);
                                    setState(() => d.dayExpanded[dpId] = nowOpen);
                                    if (nowOpen) _loadSlots(dpId);
                                  },
                                  onSlotTap: (slot, dp) => _openReservation(slot, dp),
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

// ─── Week section ─────────────────────────────────────────────────────────────

class _WeekSection extends StatelessWidget {
  const _WeekSection({
    required this.data,
    required this.fmtWeek,
    required this.busyColor,
    required this.busyLabel,
    required this.onToggleWeek,
    required this.onToggleDay,
    required this.onSlotTap,
  });

  final _AgendaData                      data;
  final String Function(String)          fmtWeek;
  final Color  Function(double)          busyColor;
  final String Function(double)          busyLabel;
  final VoidCallback                     onToggleWeek;
  final ValueChanged<int>                onToggleDay;
  final void Function(TimeSlot, DayPlan) onSlotTap;

  @override
  Widget build(BuildContext context) {
    final weekRatio = data.agenda.busyRatio;
    final wc = busyColor(weekRatio);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // ── Week header ──────────────────────────────────────────
          InkWell(
            borderRadius: data.weekExpanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            onTap: onToggleWeek,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.calendarWeek,
                          color: AppColors.neonGreen, size: 13),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(fmtWeek(data.agenda.weekStartDate),
                            style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      if (data.agenda.availableSlots != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${data.agenda.availableSlots} free',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 10),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: wc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(busyLabel(weekRatio),
                            style: GoogleFonts.inter(
                                color: wc, fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: data.weekExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const FaIcon(FontAwesomeIcons.chevronDown,
                            color: AppColors.textSecondary, size: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _BusyBar(ratio: weekRatio, color: wc),
                ],
              ),
            ),
          ),

          // ── Day plan list (visible when week expanded) ────────────
          if (data.weekExpanded) ...[
            Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: data.agenda.dayPlans.map((dp) {
                  final dayRatio  = dp.busyRatio;
                  final dc        = busyColor(dayRatio);
                  final isDayOff  = dp.dayType == DayType.day_off;
                  final expanded  = data.dayExpanded[dp.id] ?? false;
                  // Reads from TimeSlotProvider — null means loading.
                  final slotProv  = context.watch<TimeSlotProvider>();
                  final slots     = slotProv.slots(dp.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          // ── Day header ───────────────────────────
                          InkWell(
                            borderRadius: expanded
                                ? const BorderRadius.vertical(
                                    top: Radius.circular(12))
                                : BorderRadius.circular(12),
                            onTap: () => onToggleDay(dp.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(dp.dayOfWeek.name,
                                              style: GoogleFonts.inter(
                                                  color: isDayOff
                                                      ? AppColors.textSecondary
                                                      : AppColors.textPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 6),
                                          Text(dp.date,
                                              style: GoogleFonts.inter(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 10)),
                                        ]),
                                        const SizedBox(height: 4),
                                        if (isDayOff)
                                          Text('Day off',
                                              style: GoogleFonts.inter(
                                                  color: Colors.redAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600))
                                        else
                                          _BusyBar(ratio: dayRatio, color: dc, height: 4),
                                      ],
                                    ),
                                  ),
                                  if (!isDayOff) ...[
                                    const SizedBox(width: 8),
                                    Text(busyLabel(dayRatio),
                                        style: GoogleFonts.inter(
                                            color: dc, fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                  ],
                                  AnimatedRotation(
                                    turns: expanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const FaIcon(FontAwesomeIcons.chevronDown,
                                        color: AppColors.textSecondary, size: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Slot list (visible when day expanded) ─
                          if (expanded && !isDayOff) ...[
                            Divider(color: AppColors.divider, height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                              child: slots == null
                                  // Loading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: CircularProgressIndicator(
                                            color: AppColors.neonGreen,
                                            strokeWidth: 2),
                                      ))
                                  : slots.isEmpty
                                      ? Text('No time slots.',
                                          style: GoogleFonts.inter(
                                              color: AppColors.textSecondary,
                                              fontSize: 12))
                                      : Column(
                                          children: slots.map((s) => _SlotTile(
                                                slot:  s,
                                                onTap: s.isActive
                                                    ? () => onSlotTap(s, dp)
                                                    : null,
                                              )).toList(),
                                        ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Busyness bar ─────────────────────────────────────────────────────────────

class _BusyBar extends StatelessWidget {
  const _BusyBar({required this.ratio, required this.color, this.height = 5});
  final double ratio;
  final Color  color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value:           ratio,
          minHeight:       height,
          backgroundColor: AppColors.surfaceVariant,
          valueColor:      AlwaysStoppedAnimation<Color>(color),
        ),
      );
}

// ─── Slot tile ────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onTap});
  final TimeSlot     slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ok = slot.isActive && slot.startTime.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: ok
            ? const Color.fromRGBO(46, 204, 113, 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: ok ? AppColors.neonGreen : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  slot.startTime.isNotEmpty
                      ? '${slot.startTime}  –  ${slot.endTime}'
                      : 'Slot #${slot.id}',
                  style: GoogleFonts.montserrat(
                      color: ok ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (ok)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Book',
                        style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  )
                else
                  Text('Reserved',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Text('Retry',
                style: GoogleFonts.inter(
                    color: AppColors.neonGreen, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

// ─── Reservation bottom sheet ─────────────────────────────────────────────────

class _ReservationSheet extends StatefulWidget {
  final TimeSlot slot;
  final DayPlan  dayPlan;
  final Terrain  terrain;
  final Campus   campus;

  const _ReservationSheet({
    required this.slot,
    required this.dayPlan,
    required this.terrain,
    required this.campus,
  });

  @override
  State<_ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<_ReservationSheet> {
  ReservationType _type    = ReservationType.normal;
  final _notesCtrl         = TextEditingController();
  bool  _loading           = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<ReservationService>().createReservation(
        CreateReservationRequest(
          timeSlotId: widget.slot.id,
          campusId:   widget.campus.id,
          terrainId:  widget.terrain.id,
          type:       _type,
          notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Booking confirmed!',
            style: GoogleFonts.inter(
                color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context, true);
    } on ServiceException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Book a Slot',
              style: GoogleFonts.montserrat(
                  color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          // ── Summary card ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color.fromRGBO(46, 204, 113, 0.3)),
            ),
            child: Column(children: [
              _Row(icon: FontAwesomeIcons.building, label: widget.campus.name),
              const SizedBox(height: 8),
              _Row(icon: FontAwesomeIcons.trophy,   label: widget.terrain.type.name),
              const SizedBox(height: 8),
              _Row(icon: FontAwesomeIcons.calendarDay,
                  label: '${widget.dayPlan.dayOfWeek.name}  ${widget.dayPlan.date}'),
              const SizedBox(height: 8),
              _Row(icon: FontAwesomeIcons.clock,
                  label: '${widget.slot.startTime}  –  ${widget.slot.endTime}'),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Type toggle ────────────────────────────────────────────
          Text('Reservation Type',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11.5,
                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Row(
            children: ReservationType.values.map((rt) {
              final selected = _type == rt;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: rt == ReservationType.normal ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = rt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.neonGreen : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.neonGreen : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        rt.name[0].toUpperCase() + rt.name.substring(1),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: selected ? Colors.black : AppColors.textSecondary,
                          fontWeight: FontWeight.w700, fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Notes ──────────────────────────────────────────────────
          Text('Notes',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11.5,
                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Optional — any special requests',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Submit ─────────────────────────────────────────────────
          _loading
              ? const Center(child: CircularProgressIndicator(
                    color: AppColors.neonGreen))
              : SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.neonGreen,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text('CONFIRM BOOKING',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});
  final dynamic icon;
  final String  label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          FaIcon(icon, color: AppColors.neonGreen, size: 12),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      );
}
