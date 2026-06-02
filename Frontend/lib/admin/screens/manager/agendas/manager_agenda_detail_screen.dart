import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/crud_modal.dart';
import 'package:flutter/material.dart';

class ManagerAgendaDetailScreen extends StatefulWidget {
  const ManagerAgendaDetailScreen({
    super.key, required this.agendaId, required this.agendaTitle});
  final int    agendaId;
  final String agendaTitle;

  @override
  State<ManagerAgendaDetailScreen> createState() => _ManagerAgendaDetailScreenState();
}

class _ManagerAgendaDetailScreenState extends State<ManagerAgendaDetailScreen> {
  Map<String, dynamic>? _agenda;
  bool    _loading = true;
  String? _error;
  bool    _publishing = false;

  // Expanded day plans
  final Set<int> _expanded = {};

  // Day plan type edit
  Map<String, dynamic>? _editDayPlan;
  String _editDayType = 'normal';
  bool   _savingDayPlan = false;

  // Add slot modal
  Map<String, dynamic>? _addSlotToDayPlan;
  final _slotStart = TextEditingController(text: '14:00');
  final _slotEnd   = TextEditingController(text: '16:00');
  bool  _savingSlot = false;
  String? _slotError;

  // Delete slot
  Map<String, dynamic>? _deleteSlot;
  bool _deletingSlot = false;

  static const _dayTypes = ['normal', 'urgent_only', 'day_off'];

  @override
  void initState() { super.initState(); _fetch(); }
  @override
  void dispose() { _slotStart.dispose(); _slotEnd.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await AdminClient.get('/week-agendas/${widget.agendaId}');
      final data = r.data as Map<String, dynamic>;
      final agendaData = data['agenda'] ?? data;
      if (mounted) setState(() { _agenda = agendaData as Map<String, dynamic>; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = AdminClient.errorMessage(e); _loading = false; });
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      await AdminClient.post('/manager/week-agendas/${widget.agendaId}/publish', null);
      if (!mounted) return;
      _fetch();
    } catch (e) {
      if (mounted) _showMsg('Failed to publish: $e', isError: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _saveDayPlan() async {
    setState(() => _savingDayPlan = true);
    try {
      await AdminClient.put('/manager/day-plans/${_editDayPlan!['id']}',
          {'dayType': _editDayType});
      if (!mounted) return;
      setState(() => _editDayPlan = null);
      _fetch();
    } catch (e) {
      if (mounted) _showMsg('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingDayPlan = false);
    }
  }

  Future<void> _addSlot() async {
    setState(() { _savingSlot = true; _slotError = null; });
    try {
      // Backend expects Strapi body: { data: { day_plan, start_time, end_time } }
      await AdminClient.post('/time-slots', {
        'data': {
          'day_plan':   _addSlotToDayPlan!['id'],
          'start_time': _slotStart.text.trim(),
          'end_time':   _slotEnd.text.trim(),
        },
      });
      if (!mounted) return;
      setState(() { _addSlotToDayPlan = null; _slotStart.text = '14:00'; _slotEnd.text = '16:00'; });
      _fetch();
    } catch (e) {
      if (mounted) setState(() => _slotError = AdminClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _savingSlot = false);
    }
  }

  Future<void> _delSlot() async {
    setState(() => _deletingSlot = true);
    try {
      await AdminClient.delete('/time-slots/${_deleteSlot!['id']}');
      if (!mounted) return;
      setState(() => _deleteSlot = null);
      _fetch();
    } catch (_) {
      if (mounted) setState(() => _deleteSlot = null);
    } finally {
      if (mounted) setState(() => _deletingSlot = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(
          color: isError ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AdminColors.danger : AdminColors.neonGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  static Color _dayTypeColor(String? t) => switch (t) {
        'normal'      => AdminColors.neonGreen,
        'urgent_only' => AdminColors.warning,
        'day_off'     => AdminColors.danger,
        _             => AdminColors.indigo,
      };

  static String _dayTypeLabel(String? t) => switch (t) {
        'normal'      => 'Normal',
        'urgent_only' => 'Urgent Only',
        'day_off'     => 'Day Off',
        _             => t ?? '—',
      };

  @override
  Widget build(BuildContext context) {
    final ext       = context.adminExt;
    final published = _agenda?['statu'] == 'Published';

    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ──────────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agenda Detail', style: TextStyle(color: ext.text, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(widget.agendaTitle, style: TextStyle(color: ext.muted, fontSize: 13)),
            ])),
            if (!published && !_loading)
              ElevatedButton.icon(
                onPressed: _publishing ? null : _publish,
                icon:  const Icon(Icons.public, size: 16, color: Colors.black),
                label: Text(_publishing ? 'Publishing…' : 'Publish',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.neonGreen,
                  disabledBackgroundColor: AdminColors.neonGreen.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            if (published)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color:        AdminColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: AdminColors.neonGreen.withValues(alpha: 0.4)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline, size: 14, color: AdminColors.neonGreen),
                  SizedBox(width: 6),
                  Text('Published', style: TextStyle(color: AdminColors.neonGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
          const SizedBox(height: 24),

          // ── Day plans ────────────────────────────────────────────────────────
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(color: AdminColors.neonGreen)))
          else if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: AdminColors.danger)))
          else
            ...(_agenda?['day_plans'] as List? ?? []).map((dp) {
              final dayPlan    = dp as Map<String, dynamic>;
              final id         = dayPlan['id'] as int;
              final isExpanded = _expanded.contains(id);
              final dayType    = dayPlan['dayType'] as String? ?? 'normal';
              // Strapi may return snake_case or camelCase depending on version
              final slots = ((dayPlan['time_slots'] ?? dayPlan['timeSlots']) as List?) ?? [];
              final dtColor    = _dayTypeColor(dayType);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color:        ext.card,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: ext.border),
                ),
                child: Column(children: [
                  // Day header
                  InkWell(
                    borderRadius: isExpanded
                        ? const BorderRadius.vertical(top: Radius.circular(14))
                        : BorderRadius.circular(14),
                    onTap: () => setState(() {
                      isExpanded ? _expanded.remove(id) : _expanded.add(id);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(dayPlan['dayOfWeek'] ?? '—',
                              style: TextStyle(color: ext.text, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(dayPlan['date'] ?? '',
                              style: TextStyle(color: ext.muted, fontSize: 11)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color:        dtColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border:       Border.all(color: dtColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(_dayTypeLabel(dayType),
                              style: TextStyle(color: dtColor, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Text('${slots.length} slot${slots.length != 1 ? 's' : ''}',
                            style: TextStyle(color: ext.subtle, fontSize: 11)),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Edit day type', icon: Icon(Icons.edit_outlined, size: 15, color: ext.muted),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => setState(() {
                            _editDayPlan = dayPlan;
                            _editDayType = dayType;
                          }),
                        ),
                        AnimatedRotation(
                          turns:    isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child:    Icon(Icons.keyboard_arrow_down, color: ext.muted, size: 20),
                        ),
                      ]),
                    ),
                  ),

                  // Slots (when expanded)
                  if (isExpanded) ...[
                    Divider(color: ext.border, height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (slots.isEmpty)
                          Text('No time slots.', style: TextStyle(color: ext.subtle, fontSize: 13))
                        else
                          Wrap(spacing: 8, runSpacing: 8, children: slots.map((s) {
                            final slot     = s as Map<String, dynamic>;
                            final isActive = slot['isActive'] == true;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color:        isActive
                                    ? AdminColors.neonGreen.withValues(alpha: 0.10)
                                    : ext.surfaceVariant ?? ext.border.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isActive
                                    ? AdminColors.neonGreen.withValues(alpha: 0.35)
                                    : ext.border),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 7, height: 7, decoration: BoxDecoration(
                                    color: isActive ? AdminColors.neonGreen : ext.subtle,
                                    shape: BoxShape.circle)),
                                const SizedBox(width: 7),
                                Text('${slot['startTime']} – ${slot['endTime']}',
                                    style: TextStyle(color: isActive ? ext.text : ext.subtle,
                                        fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => setState(() => _deleteSlot = slot),
                                  child: Icon(Icons.close, size: 13,
                                      color: ext.subtle.withValues(alpha: 0.7)),
                                ),
                              ]),
                            );
                          }).toList()),
                        const SizedBox(height: 10),
                        if (dayType != 'day_off')
                          TextButton.icon(
                            onPressed: () => setState(() { _addSlotToDayPlan = dayPlan; _slotError = null; }),
                            icon:  const Icon(Icons.add, size: 14, color: AdminColors.neonGreen),
                            label: const Text('Add slot', style: TextStyle(color: AdminColors.neonGreen, fontSize: 12)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          ),
                      ]),
                    ),
                  ],
                ]),
              );
            }),
        ]),
      ),

      // Edit day plan type
      if (_editDayPlan != null)
        CrudModal(
          title: 'Edit Day Type — ${_editDayPlan!['dayOfWeek']}',
          onClose: () => setState(() => _editDayPlan = null),
          child: StatefulBuilder(builder: (ctx, setSt) {
            final ext2 = ctx.adminExt;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: ext2.input, borderRadius: BorderRadius.circular(10), border: Border.all(color: ext2.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _editDayType, isExpanded: true, dropdownColor: ext2.card,
                    items: _dayTypes.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_dayTypeLabel(t), style: TextStyle(color: ext2.text)),
                    )).toList(),
                    onChanged: (v) => setSt(() => _editDayType = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ModalActions(onCancel: () => setState(() => _editDayPlan = null),
                  onSave: _saveDayPlan, saving: _savingDayPlan),
            ]);
          }),
        ),

      // Add slot modal
      if (_addSlotToDayPlan != null)
        CrudModal(
          title: 'Add Time Slot — ${_addSlotToDayPlan!['dayOfWeek']}',
          onClose: () => setState(() => _addSlotToDayPlan = null),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_slotError != null) ...[ModalErrorBanner(message: _slotError!), const SizedBox(height: 14)],
            Row(children: [
              Expanded(child: ModalField(label: 'Start (HH:MM)', controller: _slotStart, hint: '14:00')),
              const SizedBox(width: 12),
              Expanded(child: ModalField(label: 'End (HH:MM)', controller: _slotEnd, hint: '16:00')),
            ]),
            const SizedBox(height: 20),
            ModalActions(onCancel: () => setState(() => _addSlotToDayPlan = null),
                onSave: _addSlot, saving: _savingSlot, saveLabel: 'Add Slot'),
          ]),
        ),

      // Delete slot
      if (_deleteSlot != null)
        DeleteModal(
          title: 'Delete Slot',
          description: 'Remove slot ${_deleteSlot!['startTime']} – ${_deleteSlot!['endTime']}?',
          onConfirm: _delSlot,
          onCancel:  () => setState(() => _deleteSlot = null),
          deleting:  _deletingSlot,
        ),
    ]);
  }
}

extension _AdminExtSurface on AdminExt {
  Color? get surfaceVariant => null; // resolved at theme level
}
