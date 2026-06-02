import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:Arena/admin/widgets/crud_modal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagerCampusScreen extends StatefulWidget {
  const ManagerCampusScreen({super.key});
  @override
  State<ManagerCampusScreen> createState() => _ManagerCampusScreenState();
}

class _ManagerCampusScreenState extends State<ManagerCampusScreen> {
  List<Map<String, dynamic>> _campuses = [];
  List<Map<String, dynamic>> _terrains = [];
  bool    _loading = true;
  String? _error;

  Map<String, dynamic>? _editCampus;
  bool _showCampusModal = false, _savingCampus = false;
  String? _campusError;
  final _cName  = TextEditingController();
  final _cAddr  = TextEditingController();
  final _cPhone = TextEditingController();
  final _cDesc  = TextEditingController();

  bool _showTerrainModal = false, _savingTerrain = false;
  String? _terrainError;
  String _selType = 'Football';
  int?   _selCampusId;
  final _terrainTypes = ['Football', 'Basketball', 'Paddel', 'Tennis'];

  Map<String, dynamic>? _deleteCampus;
  Map<String, dynamic>? _deleteTerrain;
  bool _deleting = false;

  @override
  void initState() { super.initState(); _fetch(); }
  @override
  void dispose() {
    _cName.dispose(); _cAddr.dispose(); _cPhone.dispose(); _cDesc.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        AdminClient.get('/manager/get-campuses'),
        AdminClient.get('/manager/get-terrains'),
      ]);
      final cRaw = res[0].data;
      final tRaw = res[1].data;
      if (mounted) {
        setState(() {
          _campuses = ((cRaw is List ? cRaw : (cRaw['data'] ?? cRaw['campuses'] ?? [])) as List)
              .cast<Map<String, dynamic>>();
          _terrains = ((tRaw is List ? tRaw : (tRaw['terrains'] ?? tRaw['data'] ?? [])) as List)
              .cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = AdminClient.errorMessage(e); _loading = false; });
    }
  }

  void _openCreate() {
    _cName.clear(); _cAddr.clear(); _cPhone.clear(); _cDesc.clear();
    setState(() { _editCampus = null; _showCampusModal = true; _campusError = null; });
  }

  void _openEdit(Map<String, dynamic> c) {
    _cName.text  = c['Name']        ?? c['name']        ?? '';
    _cAddr.text  = c['Address']     ?? c['address']     ?? '';
    _cPhone.text = c['phone']       ?? '';
    _cDesc.text  = c['Description'] ?? c['description'] ?? '';
    setState(() { _editCampus = c; _showCampusModal = true; _campusError = null; });
  }

  Future<void> _saveCampus() async {
    setState(() { _savingCampus = true; _campusError = null; });
    try {
      final body = {
        'name': _cName.text.trim(), 'address': _cAddr.text.trim(),
        if (_cPhone.text.trim().isNotEmpty) 'phone':       _cPhone.text.trim(),
        if (_cDesc.text.trim().isNotEmpty)  'description': _cDesc.text.trim(),
      };
      if (_editCampus == null) {
        await AdminClient.post('/manager/create-campus', body);
      } else {
        await AdminClient.put('/manager/update-campus/${_editCampus!['id']}', body);
      }
      if (!mounted) return;
      setState(() { _showCampusModal = false; _editCampus = null; });
      _fetch();
    } catch (e) {
      if (mounted) setState(() => _campusError = AdminClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _savingCampus = false);
    }
  }

  Future<void> _deleteCampusOk() async {
    setState(() => _deleting = true);
    try {
      await AdminClient.delete('/manager/delete-campus/${_deleteCampus!['id']}');
      if (!mounted) return;
      setState(() => _deleteCampus = null); _fetch();
    } catch (_) { if (mounted) setState(() => _deleteCampus = null); }
    finally { if (mounted) setState(() => _deleting = false); }
  }

  void _openAddTerrain(int campusId) {
    _selType = 'Football'; _selCampusId = campusId;
    setState(() { _showTerrainModal = true; _terrainError = null; });
  }

  Future<void> _saveTerrain() async {
    setState(() { _savingTerrain = true; _terrainError = null; });
    try {
      await AdminClient.post('/manager/create-terrain', {
        'Type': _selType, 'campusId': _selCampusId,
      });
      if (!mounted) return;
      setState(() => _showTerrainModal = false); _fetch();
    } catch (e) {
      if (mounted) setState(() => _terrainError = AdminClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _savingTerrain = false);
    }
  }

  Future<void> _deleteTerrainOk() async {
    setState(() => _deleting = true);
    try {
      await AdminClient.delete('/manager/delete-terrain/${_deleteTerrain!['id']}');
      if (!mounted) return;
      setState(() => _deleteTerrain = null); _fetch();
    } catch (_) { if (mounted) setState(() => _deleteTerrain = null); }
    finally { if (mounted) setState(() => _deleting = false); }
  }

  List<Map<String, dynamic>> _terrainsFor(int cId) => _terrains.where((t) {
    final c = t['campus'];
    return c is Map ? c['id'] == cId : c == cId;
  }).toList();

  static Color  _clr(String? t) => switch (t) {
        'Football'   => AdminColors.emerald,
        'Basketball' => AdminColors.amber,
        'Paddel'     => AdminColors.sky,
        'Tennis'     => AdminColors.violet,
        _            => AdminColors.indigo,
      };

  static IconData _ico(String? t) => switch (t) {
        'Football'   => Icons.sports_soccer_outlined,
        'Basketball' => Icons.sports_basketball_outlined,
        _            => Icons.sports_tennis_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Stack(children: [
      RefreshIndicator(
        color: AdminColors.neonGreen, onRefresh: _fetch,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminPageHeader(title: 'Campus & Terrains',
                subtitle: 'Manage your campuses and their terrains',
                onAdd: _openCreate, addLabel: 'New Campus'),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(color: AdminColors.neonGreen)))
            else if (_error != null)
              Center(child: Text(_error!, style: const TextStyle(color: AdminColors.danger)))
            else if (_campuses.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(60),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_city_outlined, color: ext.subtle, size: 48),
                  const SizedBox(height: 14),
                  Text('No campuses yet.', style: TextStyle(color: ext.muted)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _openCreate,
                    style: ElevatedButton.styleFrom(backgroundColor: AdminColors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                    child: const Text('Create Campus', style: TextStyle(color: Colors.white)),
                  ),
                ]),
              ))
            else
              ...(_campuses.map((c) => _CampusBlock(
                campus: c, terrains: _terrainsFor(c['id'] as int),
                clr: _clr, ico: _ico,
                onEdit: () => _openEdit(c), onDelete: () => setState(() => _deleteCampus = c),
                onAddTerrain: () => _openAddTerrain(c['id'] as int),
                onDelTerrain: (t) => setState(() => _deleteTerrain = t),
                onAgendas: (t) => context.go('/manager/agendas'),
              ))),
          ]),
        ),
      ),
      if (_showCampusModal)
        CrudModal(
          title: _editCampus == null ? 'New Campus' : 'Edit Campus',
          onClose: () => setState(() { _showCampusModal = false; _editCampus = null; }),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_campusError != null) ...[ModalErrorBanner(message: _campusError!), const SizedBox(height: 14)],
            ModalField(label: 'Campus Name *', controller: _cName, hint: 'Arena Nord'),
            const SizedBox(height: 12),
            ModalField(label: 'Address *', controller: _cAddr, hint: 'Street, City'),
            const SizedBox(height: 12),
            ModalField(label: 'Phone', controller: _cPhone, hint: 'Optional', type: TextInputType.phone, optional: true),
            const SizedBox(height: 12),
            ModalField(label: 'Description', controller: _cDesc, hint: 'Optional', optional: true),
            const SizedBox(height: 20),
            ModalActions(onCancel: () => setState(() { _showCampusModal = false; _editCampus = null; }),
                onSave: _saveCampus, saving: _savingCampus),
          ]),
        ),
      if (_showTerrainModal)
        CrudModal(
          title: 'Add Terrain',
          onClose: () => setState(() => _showTerrainModal = false),
          child: StatefulBuilder(builder: (ctx, ss) {
            final e2 = ctx.adminExt;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              if (_terrainError != null) ...[ModalErrorBanner(message: _terrainError!), const SizedBox(height: 14)],
              Text('Terrain Type', style: TextStyle(color: e2.muted, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: e2.input,
                    borderRadius: BorderRadius.circular(10), border: Border.all(color: e2.border)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: _selType, isExpanded: true, dropdownColor: e2.card,
                  items: _terrainTypes.map((t) => DropdownMenuItem(value: t,
                      child: Text(t, style: TextStyle(color: e2.text)))).toList(),
                  onChanged: (v) => ss(() => _selType = v!),
                )),
              ),
              const SizedBox(height: 20),
              ModalActions(onCancel: () => setState(() => _showTerrainModal = false),
                  onSave: _saveTerrain, saving: _savingTerrain, saveLabel: 'Add Terrain'),
            ]);
          }),
        ),
      if (_deleteCampus != null)
        DeleteModal(
          title: 'Delete Campus',
          description: 'Delete "${_deleteCampus!['Name'] ?? _deleteCampus!['name']}"? This cannot be undone.',
          onConfirm: _deleteCampusOk,
          onCancel:  () => setState(() => _deleteCampus = null),
          deleting:  _deleting,
        ),
      if (_deleteTerrain != null)
        DeleteModal(
          title: 'Delete Terrain',
          description: 'Delete this ${_deleteTerrain!['Type'] ?? _deleteTerrain!['type']} terrain and all its agendas?',
          onConfirm: _deleteTerrainOk,
          onCancel:  () => setState(() => _deleteTerrain = null),
          deleting:  _deleting,
        ),
    ]);
  }
}

class _CampusBlock extends StatelessWidget {
  const _CampusBlock({required this.campus, required this.terrains,
    required this.clr, required this.ico,
    required this.onEdit, required this.onDelete,
    required this.onAddTerrain, required this.onDelTerrain, required this.onAgendas});
  final Map<String, dynamic> campus;
  final List<Map<String, dynamic>> terrains;
  final Color  Function(String?) clr;
  final IconData Function(String?) ico;
  final VoidCallback onEdit, onDelete, onAddTerrain;
  final void Function(Map<String, dynamic>) onDelTerrain, onAgendas;

  @override
  Widget build(BuildContext context) {
    final ext  = context.adminExt;
    final name = campus['Name'] ?? campus['name'] ?? '—';
    final addr = campus['Address'] ?? campus['address'] ?? '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(color: ext.card,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: ext.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 8, 16), child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AdminColors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_city_outlined, color: AdminColors.indigo, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(color: ext.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(addr, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ext.muted, fontSize: 12)),
          ])),
          IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: ext.muted), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.danger), onPressed: onDelete),
        ])),
        Divider(color: ext.border, height: 1),
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 4), child: Row(children: [
          Text('Terrains (${terrains.length})',
              style: TextStyle(color: ext.text, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(onPressed: onAddTerrain,
            icon: const Icon(Icons.add, size: 14, color: AdminColors.neonGreen),
            label: const Text('Add Terrain',
                style: TextStyle(color: AdminColors.neonGreen, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ])),
        if (terrains.isEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Text('No terrains yet.', style: TextStyle(color: ext.subtle, fontSize: 13)))
        else
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230, crossAxisSpacing: 12,
                  mainAxisSpacing: 12, childAspectRatio: 1.8),
              itemCount: terrains.length,
              itemBuilder: (_, i) => _TCard(
                t: terrains[i], clr: clr, ico: ico,
                onAgendas: () => onAgendas(terrains[i]),
                onDel:     () => onDelTerrain(terrains[i]),
              ),
            )),
      ]),
    );
  }
}

class _TCard extends StatelessWidget {
  const _TCard({required this.t, required this.clr, required this.ico,
    required this.onAgendas, required this.onDel});
  final Map<String, dynamic> t;
  final Color  Function(String?) clr;
  final IconData Function(String?) ico;
  final VoidCallback onAgendas, onDel;

  @override
  Widget build(BuildContext context) {
    final ext    = context.adminExt;
    final type   = (t['Type'] ?? t['type'] ?? '—').toString();
    final c      = clr(type);
    final empFld = t['employee'];
    final emp    = empFld is Map ? (empFld['username'] ?? empFld['nom']) : null;
    final ags    = ((t['weekAgenda'] ?? t['week_agenda']) as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.30))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(ico(type), size: 16, color: c),
          const SizedBox(width: 7),
          Expanded(child: Text(type, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w700))),
          GestureDetector(onTap: onDel,
              child: Icon(Icons.close, size: 15, color: c.withValues(alpha: 0.6))),
        ]),
        Row(children: [
          Icon(Icons.person_outline, size: 12, color: ext.muted), const SizedBox(width: 4),
          Expanded(child: Text(emp?.toString() ?? 'No employee',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ext.muted, fontSize: 11))),
        ]),
        Row(children: [
          Text('$ags agenda${ags != 1 ? 's' : ''}', style: TextStyle(color: ext.subtle, fontSize: 11)),
          const Spacer(),
          GestureDetector(onTap: onAgendas, child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_today_outlined, size: 11, color: c), const SizedBox(width: 3),
            Text('Agendas', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ]),
    );
  }
}
