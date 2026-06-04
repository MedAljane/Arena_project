import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:Arena/admin/widgets/crud_modal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagerAgendasScreen extends StatefulWidget {
  const ManagerAgendasScreen({super.key});
  @override
  State<ManagerAgendasScreen> createState() => _ManagerAgendasScreenState();
}

class _ManagerAgendasScreenState extends State<ManagerAgendasScreen> {
  List<Map<String, dynamic>> _terrains = [];
  bool    _loading = true;
  String? _error;

  bool _showCreate    = false;
  bool _saving        = false;
  String? _createError;
  int?    _selTerrainId;
  int?    _selCampusId;
  DateTime? _weekStart;

  Map<String, dynamic>? _deleteTarget;
  bool _deleting = false;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await AdminClient.get('/manager/get-terrains');
      final data = r.data;
      final raw  = data is List ? data : (data['terrains'] ?? data['data'] ?? []);
      final list = raw as List;
      if (mounted) {
        setState(() {
          _terrains = list.cast<Map<String, dynamic>>();
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = AdminClient.errorMessage(e); _loading = false; });
    }
  }

  Future<void> _createAgenda() async {
    if (_selTerrainId == null || _selCampusId == null || _weekStart == null) {
      setState(() => _createError = 'Please select terrain and week start date.');
      return;
    }
    setState(() { _saving = true; _createError = null; });
    try {
      final terrain = _terrains.firstWhere((t) => t['id'] == _selTerrainId);
      await AdminClient.post('/manager/week-agendas', {
        'weekStartDate': _weekStart!.toIso8601String().split('T')[0],
        'campusId':      _selCampusId,
        'terrainId':     _selTerrainId,
        'terrainType':   terrain['Type'] ?? terrain['type'],
      });
      if (!mounted) return;
      setState(() { _showCreate = false; _selTerrainId = null; _selCampusId = null; _weekStart = null; });
      _fetch();
    } catch (e) {
      if (mounted) setState(() => _createError = AdminClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish(int agendaId) async {
    try {
      await AdminClient.post('/manager/week-agendas/$agendaId/publish', null);
      _fetch();
    } catch (_) {}
  }

  Future<void> _deleteAgenda() async {
    setState(() => _deleting = true);
    try {
      await AdminClient.delete('/manager/week-agendas/${_deleteTarget!['id']}');
      if (!mounted) return;
      setState(() => _deleteTarget = null);
      _fetch();
    } catch (_) {
      if (mounted) setState(() => _deleteTarget = null);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final picked = await showDatePicker(
      context:     context,
      initialDate: monday,
      firstDate:   now.subtract(const Duration(days: 30)),
      lastDate:    now.add(const Duration(days: 365)),
      builder:     (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AdminColors.neonGreen, onPrimary: Colors.black,
            surface: AdminColors.darkCard,  onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _weekStart = picked);
  }

  String _fmtDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final end = dt.add(const Duration(days: 6));
    return '${m[dt.month-1]} ${dt.day} – ${m[end.month-1]} ${end.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;

    final List<_AgendaRow> all = [];
    for (final terrain in _terrains) {
      final agendas = terrain['weekAgenda'] ?? terrain['week_agenda'] ?? [];
      if (agendas is List) {
        for (final a in agendas) {
          all.add(_AgendaRow(terrain: terrain, agenda: a as Map<String, dynamic>));
        }
      }
    }
    all.sort((a, b) => (b.agenda['weekStartDate'] ?? '').compareTo(a.agenda['weekStartDate'] ?? ''));

    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminPageHeader(
            title: 'Week Agendas', subtitle: 'Manage terrain schedules and time slots',
            onAdd: () => setState(() { _showCreate = true; _createError = null; _selTerrainId = null; _selCampusId = null; _weekStart = null; }),
            addLabel: 'New Agenda',
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(color: AdminColors.neonGreen)))
          else if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: AdminColors.danger)))
          else if (all.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(60),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_outlined, color: ext.subtle, size: 48),
                  const SizedBox(height: 16),
                  Text('No agendas yet.', style: TextStyle(color: ext.muted, fontSize: 15)),
                ])))
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: ext.card, border: Border.all(color: ext.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(3),
                    3: FlexColumnWidth(2),
                    4: FixedColumnWidth(100),
                    5: IntrinsicColumnWidth(),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ext.border))),
                      children: [
                        _th('ID', ext), _th('Terrain', ext), _th('Week', ext),
                        _th('Campus', ext), _th('Days', ext), _th('Actions', ext),
                      ],
                    ),
                    ...all.map((row) {
                      final a       = row.agenda;
                      final t       = row.terrain;
                      final published = a['statu'] == 'Published';
                      final color   = published ? AdminColors.neonGreen : AdminColors.warning;
                      final days    = (a['day_plans'] as List?)?.length ?? 0;

                      return TableRow(
                        decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: ext.border.withValues(alpha: 0.5)))),
                        children: [
                          _td(Text('${a['id']}', style: TextStyle(color: ext.subtle, fontSize: 12, fontFamily: 'monospace'))),
                          _td(Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AdminColors.emerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.35)),
                              ),
                              child: Text(t['Type'] ?? t['type'] ?? '—',
                                  style: const TextStyle(color: AdminColors.emerald, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ])),
                          _td(Text(_fmtDate(a['weekStartDate'] ?? ''), style: TextStyle(color: ext.text, fontSize: 13))),
                          _td(Text((t['campus'] as Map?)?['Name'] ?? '—', style: TextStyle(color: ext.muted, fontSize: 13))),
                          _td(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withValues(alpha: 0.35)),
                            ),
                            child: Text('$days/7', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                          )),
                          _td(Wrap(spacing: 6, runSpacing: 4, children: [
                            _btn('Edit', AdminColors.indigo,
                                () => context.go('/manager/agendas/${a['id']}?title=${_fmtDate(a['weekStartDate'] ?? '')}')),
                            if (!published)
                              _btn('Publish', AdminColors.neonGreen, () => _publish(a['id'] as int)),
                            _btn('Delete', AdminColors.danger, () => setState(() => _deleteTarget = a)),
                          ])),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
        ]),
      ),

      if (_showCreate)
        CrudModal(
          title: 'New Week Agenda',
          onClose: () => setState(() => _showCreate = false),
          child: StatefulBuilder(builder: (ctx, setSt) {
            final ext2 = ctx.adminExt;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              if (_createError != null) ...[ModalErrorBanner(message: _createError!), const SizedBox(height: 14)],

              Text('Terrain', style: TextStyle(color: ext2.muted, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: ext2.input, borderRadius: BorderRadius.circular(10), border: Border.all(color: ext2.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selTerrainId, isExpanded: true, dropdownColor: ext2.card,
                    hint: Text('Select terrain', style: TextStyle(color: ext2.subtle)),
                    items: _terrains.map((t) => DropdownMenuItem<int?>(
                      value: t['id'] as int?,
                      child: Text('${t['Type'] ?? t['type']} — ${(t['campus'] as Map?)?['Name'] ?? 'Campus'}',
                          style: TextStyle(color: ext2.text)),
                    )).toList(),
                    onChanged: (v) {
                      setSt(() {
                        _selTerrainId = v;
                        if (v != null) {
                          final t = _terrains.firstWhere((t) => t['id'] == v, orElse: () => {});
                          _selCampusId = (t['campus'] as Map?)?['id'] as int?;
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Week Start Date', style: TextStyle(color: ext2.muted, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: ext2.input, borderRadius: BorderRadius.circular(10), border: Border.all(color: ext2.border)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: ext2.muted),
                    const SizedBox(width: 10),
                    Text(_weekStart == null ? 'Select date' : _fmtDate(_weekStart!.toIso8601String()),
                        style: TextStyle(color: _weekStart == null ? ext2.subtle : ext2.text, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              ModalActions(onCancel: () => setState(() => _showCreate = false), onSave: _createAgenda, saving: _saving, saveLabel: 'Create Agenda'),
            ]);
          }),
        ),

      if (_deleteTarget != null)
        DeleteModal(
          title: 'Delete Agenda',
          description: 'Delete this agenda for ${_fmtDate(_deleteTarget!['weekStartDate'] ?? '')}? All day plans and time slots will be removed.',
          onConfirm: _deleteAgenda,
          onCancel:  () => setState(() => _deleteTarget = null),
          deleting:  _deleting,
        ),
    ]);
  }

  static TableCell _th(String label, AdminExt ext) => TableCell(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Text(label.toUpperCase(), style: TextStyle(color: ext.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
  ));

  static TableCell _td(Widget child) => TableCell(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: child));

  static Widget _btn(String label, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  );
}

class _AgendaRow {
  const _AgendaRow({required this.terrain, required this.agenda});
  final Map<String, dynamic> terrain;
  final Map<String, dynamic> agenda;
}
