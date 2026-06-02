import 'package:Arena/models/models.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AgendaDetailScreen extends StatefulWidget {
  final WeekAgendaSummary summary;
  final TerrainType terrainType;

  const AgendaDetailScreen({
    super.key,
    required this.summary,
    required this.terrainType,
  });

  @override
  State<AgendaDetailScreen> createState() => _AgendaDetailScreenState();
}

class _AgendaDetailScreenState extends State<AgendaDetailScreen> {
  WeekAgenda? _agenda;
  bool        _loading    = true;
  String?     _error;
  bool        _publishing = false;
  bool        _deleting   = false;
  // Day-plan list, expand/collapse, and slot-loading state live in DayPlanProvider.

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ag = await context.read<WeekAgendaService>().getWeekAgenda(widget.summary.id);
      if (mounted) {
        // Seed the provider with day plans from the freshly loaded agenda.
        context.read<DayPlanProvider>().setForAgenda(ag.dayPlans);
        setState(() { _agenda = ag; _loading = false; });
      }
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  /// Delegates expand/collapse + lazy slot loading to DayPlanProvider.
  void _toggleDay(DayPlan dp) {
    context.read<DayPlanProvider>().toggle(dp.id, context.read<WeekAgendaService>());
  }

  /// Re-fetches a day plan after any slot mutation (add/edit/delete).
  Future<void> _refreshDayPlan(int dayPlanId) =>
      context.read<DayPlanProvider>().refreshDayPlan(
            dayPlanId, context.read<WeekAgendaService>());

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      await context.read<WeekAgendaService>().publishWeekAgenda(widget.summary.id);
      if (!mounted) return;
      _showMsg('Agenda published! Players can now see available slots.');
      _fetchAll();
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _deleteAgenda() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Agenda?',
            style: GoogleFonts.montserrat(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This permanently removes the agenda, all 7 day plans, and every time slot inside.\n'
          'Week starting ${_fmtRange(widget.summary.weekStartDate)}.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<WeekAgendaService>().deleteWeekAgenda(widget.summary.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Agenda deleted.',
            style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context); // return to terrain detail
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _deleteDayPlan(DayPlan dp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${dp.dayOfWeek.name}?',
            style: GoogleFonts.montserrat(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes the day plan and all its time slots.\n${dp.date}',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<WeekAgendaService>().deleteDayPlan(dp.id);
      _showMsg('${dp.dayOfWeek.name} deleted.');
      if (mounted) context.read<DayPlanProvider>().removeDayPlan(dp.id);
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    }
  }

  Future<void> _addSlot(DayPlan dp) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddSlotSheet(),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<WeekAgendaService>().createTimeSlot(
        CreateTimeSlotRequest(
          dayPlanId: dp.id,
          startTime: result['start']!,
          endTime:   result['end']!,
        ),
      );
      _showMsg('Slot added.');
      await _refreshDayPlan(dp.id);
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    }
  }

  Future<void> _editSlot(DayPlan dp, TimeSlot slot) async {
    final result = await showModalBottomSheet<_SlotEdit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditSlotSheet(slot: slot),
    );
    if (result == null || !mounted) return;

    final svc = context.read<WeekAgendaService>();
    try {
      if (result.deleteAndRecreate) {
        // Backend can't update startTime/endTime directly: delete + recreate.
        await svc.deleteTimeSlot(slot.id);
        await svc.createTimeSlot(CreateTimeSlotRequest(
          dayPlanId: dp.id,
          startTime: result.startTime,
          endTime:   result.endTime,
        ));
        _showMsg('Slot updated.');
      } else {
        // Only isActive changed — safe to PUT.
        await svc.updateTimeSlot(slot.id, UpdateTimeSlotRequest(isActive: result.isActive));
        _showMsg(result.isActive! ? 'Slot activated.' : 'Slot deactivated.');
      }
      await _refreshDayPlan(dp.id);
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    }
  }

  Future<void> _deleteSlot(DayPlan dp, int slotId) async {
    try {
      await context.read<WeekAgendaService>().deleteTimeSlot(slotId);
      _showMsg('Slot removed.');
      await _refreshDayPlan(dp.id);
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
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

  // ── UI helpers ─────────────────────────────────────────────────────────────

  String _fmtRange(String start) {
    final dt = DateTime.tryParse(start);
    if (dt == null) return start;
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    final end = dt.add(const Duration(days: 6));
    return '${m[dt.month-1]} ${dt.day} – ${m[end.month-1]} ${end.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dpProv  = context.watch<DayPlanProvider>();
    final hPad    = MediaQuery.of(context).size.width * 0.052;
    final isDraft = (_agenda?.statu ?? widget.summary.statu) == WeekAgendaStatus.Draft;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
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
                        Text(widget.terrainType.name,
                            style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(_fmtRange(widget.summary.weekStartDate),
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  _StatusBadge(statu: _agenda?.statu ?? widget.summary.statu),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 20),

            // ── Publish / Delete bar ─────────────────────────────────
            if (!_loading)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
                child: Column(
                  children: [
                    // Publish — Draft only
                    if (isDraft)
                      _publishing
                          ? const Center(child: CircularProgressIndicator(
                                color: AppColors.neonGreen, strokeWidth: 2))
                          : Material(
                              color: AppColors.neonGreen,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _publish,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const FaIcon(FontAwesomeIcons.earthAfrica,
                                          color: Colors.black, size: 13),
                                      const SizedBox(width: 8),
                                      Text('Publish Agenda',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    if (isDraft) const SizedBox(height: 8),
                    // Delete — always visible
                    _deleting
                        ? const Center(child: CircularProgressIndicator(
                              color: Colors.redAccent, strokeWidth: 2))
                        : Material(
                            color: const Color.fromRGBO(255, 59, 48, 0.08),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _deleteAgenda,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(FontAwesomeIcons.trashCan,
                                        color: Colors.redAccent, size: 13),
                                    const SizedBox(width: 8),
                                    Text('Delete Agenda',
                                        style: GoogleFonts.montserrat(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),

            // ── Day plan list ────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                        color: AppColors.neonGreen))
                  : _error != null
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error!,
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _fetchAll,
                            child: Text('Retry',
                                style: GoogleFonts.inter(
                                    color: AppColors.neonGreen,
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ]))
                      : dpProv.dayPlans.isEmpty
                          ? Center(child: Text('No day plans.',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 13)))
                          : RefreshIndicator(
                              color: AppColors.neonGreen,
                              onRefresh: _fetchAll,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                                itemCount: dpProv.dayPlans.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final dp = dpProv.dayPlans[i];
                                  return _DayCard(
                                    dayPlan:      dp,
                                    expanded:     dpProv.isExpanded(dp.id),
                                    slotsLoading: dpProv.isLoadingSlots(dp.id),
                                    onToggle:     () => _toggleDay(dp),
                                    onDelete:     () => _deleteDayPlan(dp),
                                    onAddSlot:    dp.dayType != DayType.day_off
                                        ? () => _addSlot(dp) : null,
                                    onEditSlot:   (s) => _editSlot(dp, s),
                                    onDeleteSlot: (id) => _deleteSlot(dp, id),
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

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.statu});
  final WeekAgendaStatus statu;

  @override
  Widget build(BuildContext context) {
    final color = statu == WeekAgendaStatus.Published
        ? AppColors.neonGreen : const Color(0xFFFFC107);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(statu.name,
          style: GoogleFonts.inter(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Day plan card ────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.dayPlan,
    required this.expanded,
    required this.slotsLoading,
    required this.onToggle,
    required this.onDelete,
    required this.onAddSlot,
    required this.onEditSlot,
    required this.onDeleteSlot,
  });

  final DayPlan      dayPlan;
  final bool         expanded;
  final bool         slotsLoading;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onAddSlot;
  final ValueChanged<TimeSlot> onEditSlot;
  final ValueChanged<int>      onDeleteSlot;

  static Color _dayTypeColor(DayType t) => switch (t) {
        DayType.normal      => AppColors.neonGreen,
        DayType.urgent_only => const Color(0xFFFFC107),
        DayType.day_off     => Colors.redAccent,
      };

  static String _dayTypeLabel(DayType t) => switch (t) {
        DayType.normal      => 'Normal',
        DayType.urgent_only => 'Urgent Only',
        DayType.day_off     => 'Day Off',
      };

  static Color _busyColor(int pct) {
    if (pct < 30)  return const Color(0xFF2ECC71);
    if (pct < 65)  return const Color(0xFFFFC107);
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final dtColor  = _dayTypeColor(dayPlan.dayType);
    final slots    = dayPlan.timeSlots;
    final isDayOff = dayPlan.dayType == DayType.day_off;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          InkWell(
            borderRadius: expanded
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dayPlan.dayOfWeek.name,
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(dayPlan.date,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      // Available/total slots
                      if (!isDayOff && dayPlan.totalSlots != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${dayPlan.availableSlots ?? 0}/${dayPlan.totalSlots} free',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                      // Day type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: dtColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: dtColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(_dayTypeLabel(dayPlan.dayType),
                            style: GoogleFonts.inter(
                                color: dtColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: FaIcon(FontAwesomeIcons.trashCan,
                              color: Colors.redAccent, size: 13),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const FaIcon(FontAwesomeIcons.chevronDown,
                            color: AppColors.textSecondary, size: 11),
                      ),
                    ],
                  ),
                  // Busyness bar for non-day-off days
                  if (!isDayOff && dayPlan.busyness > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: dayPlan.busyRatio,
                        minHeight: 3,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _busyColor(dayPlan.busyness)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Slot list (when expanded) ────────────────────────────
          if (expanded) ...[
            Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: slotsLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(
                            color: AppColors.neonGreen, strokeWidth: 2),
                      ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (slots.isEmpty)
                          Text('No time slots.',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12))
                        else
                          ...slots.map((s) => _SlotRow(
                                slot:     s,
                                onEdit:   () => onEditSlot(s),
                                onDelete: s.reservation == null
                                    ? () => onDeleteSlot(s.id)
                                    : null,
                              )),
                        if (onAddSlot != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: onAddSlot,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.plus,
                                    color: AppColors.neonGreen, size: 11),
                                const SizedBox(width: 6),
                                Text('Add time slot',
                                    style: GoogleFonts.inter(
                                        color: AppColors.neonGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.onEdit,
    required this.onDelete,
  });
  final TimeSlot slot;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: slot.isActive ? AppColors.neonGreen : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('${slot.startTime} – ${slot.endTime}',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            if (!slot.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('reserved',
                    style: GoogleFonts.inter(
                        color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            const Spacer(),
            // Edit
            GestureDetector(
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: FaIcon(FontAwesomeIcons.penToSquare,
                    color: AppColors.textSecondary, size: 13),
              ),
            ),
            const SizedBox(width: 4),
            // Delete (disabled for reserved slots)
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: FaIcon(FontAwesomeIcons.trashCan,
                      color: Colors.redAccent, size: 13),
                ),
              )
            else
              const SizedBox(width: 21),
          ],
        ),
      );
}

// ─── Edit slot result ─────────────────────────────────────────────────────────

class _SlotEdit {
  const _SlotEdit.timeChange(this.startTime, this.endTime)
      : deleteAndRecreate = true,
        isActive = null;
  const _SlotEdit.toggleActive(this.isActive)
      : deleteAndRecreate = false,
        startTime = '',
        endTime = '';

  final bool    deleteAndRecreate;
  final String  startTime;
  final String  endTime;
  final bool?   isActive;
}

// ─── Edit slot bottom sheet ───────────────────────────────────────────────────

class _EditSlotSheet extends StatefulWidget {
  const _EditSlotSheet({required this.slot});
  final TimeSlot slot;

  @override
  State<_EditSlotSheet> createState() => _EditSlotSheetState();
}

class _EditSlotSheetState extends State<_EditSlotSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _start = _parse(widget.slot.startTime);
    _end   = _parse(widget.slot.endTime);
  }

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _timeChanged =>
      _fmt(_start) != widget.slot.startTime || _fmt(_end) != widget.slot.endTime;

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonGreen,
            onPrimary: Colors.black,
            surface: AppColors.surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Slot',
                style: GoogleFonts.montserrat(
                    color: AppColors.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Changing the time replaces the slot (delete + recreate).',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _TimeTile(label: 'Start', time: _fmt(_start),
                    onTap: () => _pickTime(true))),
                const SizedBox(width: 12),
                Expanded(child: _TimeTile(label: 'End', time: _fmt(_end),
                    onTap: () => _pickTime(false))),
              ],
            ),
            const SizedBox(height: 16),
            // Active toggle
            Material(
              color: widget.slot.isActive
                  ? const Color.fromRGBO(255, 59, 48, 0.08)
                  : const Color.fromRGBO(46, 204, 113, 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(
                    context, _SlotEdit.toggleActive(!widget.slot.isActive)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        widget.slot.isActive
                            ? FontAwesomeIcons.ban
                            : FontAwesomeIcons.circleCheck,
                        color: widget.slot.isActive ? Colors.redAccent : AppColors.neonGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.slot.isActive ? 'Deactivate Slot' : 'Activate Slot',
                        style: GoogleFonts.montserrat(
                          color: widget.slot.isActive ? Colors.redAccent : AppColors.neonGreen,
                          fontWeight: FontWeight.w700, fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_timeChanged) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.neonGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(
                        context, _SlotEdit.timeChange(_fmt(_start), _fmt(_end))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Text('SAVE TIME CHANGE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

// ─── Add slot / time picker tile (shared) ────────────────────────────────────

class _AddSlotSheet extends StatefulWidget {
  const _AddSlotSheet();

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  TimeOfDay _start = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 16, minute: 0);

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonGreen,
            onPrimary: Colors.black,
            surface: AppColors.surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Time Slot',
                style: GoogleFonts.montserrat(
                    color: AppColors.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _TimeTile(label: 'Start', time: _fmt(_start),
                    onTap: () => _pick(true))),
                const SizedBox(width: 12),
                Expanded(child: _TimeTile(label: 'End',   time: _fmt(_end),
                    onTap: () => _pick(false))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(
                      context, {'start': _fmt(_start), 'end': _fmt(_end)}),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('ADD SLOT',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.time, required this.onTap});
  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(46, 204, 113, 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(time,
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}
