import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:Arena/admin/widgets/crud_modal.dart';
import 'package:flutter/material.dart';

class ManagerEmployeesWebScreen extends StatefulWidget {
  const ManagerEmployeesWebScreen({super.key});
  @override
  State<ManagerEmployeesWebScreen> createState() =>
      _ManagerEmployeesWebScreenState();
}

class _ManagerEmployeesWebScreenState
    extends State<ManagerEmployeesWebScreen> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _terrains  = [];
  bool    _loading = true;
  String? _error;
  String  _search  = '';

  Map<String, dynamic>? _editTarget;
  bool _showCreate = false, _saving = false;
  String? _apiError;
  final _u    = TextEditingController();
  final _e    = TextEditingController();
  final _p    = TextEditingController();
  final _ph   = TextEditingController();
  final _addr = TextEditingController();

  Map<String, dynamic>? _deleteTarget;
  bool _deleting = false;

  Map<String, dynamic>? _assignTarget;
  int?    _assignTerrainId;
  int?    _assignCampusId;      // campus filter inside the modal
  bool    _assigning = false;
  String? _assignError;

  @override
  void initState() { super.initState(); _fetch(); }
  @override
  void dispose() {
    _u.dispose(); _e.dispose(); _p.dispose(); _ph.dispose(); _addr.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        AdminClient.get('/manager/employees'),
        AdminClient.get('/manager/get-terrains'),
      ]);
      final eData = res[0].data;
      final tData = res[1].data;
      if (mounted) {
        setState(() {
          _employees = (eData is List
                  ? eData
                  : ((eData['result'] ?? eData['data'] ?? []) as List))
              .cast<Map<String, dynamic>>();
          _terrains = (tData is List
                  ? tData
                  : ((tData['terrains'] ?? tData['data'] ?? []) as List))
              .cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = AdminClient.errorMessage(e); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _employees;
    final q = _search.toLowerCase();
    return _employees.where((e) =>
        (e['username'] ?? '').toString().toLowerCase().contains(q) ||
        (e['email']    ?? '').toString().toLowerCase().contains(q)).toList();
  }

  void _openCreate() {
    _u.clear(); _e.clear(); _p.clear(); _ph.clear(); _addr.clear();
    setState(() { _editTarget = null; _showCreate = true; _apiError = null; });
  }

  void _openEdit(Map<String, dynamic> row) {
    _u.text    = row['username'] ?? '';
    _e.text    = row['email']    ?? '';
    _p.clear();
    _ph.text   = row['phone']   ?? '';
    _addr.text = row['address'] ?? '';
    setState(() { _editTarget = row; _showCreate = true; _apiError = null; });
  }

  Future<void> _save() async {
    setState(() { _saving = true; _apiError = null; });
    try {
      if (_editTarget == null) {
        await AdminClient.post('/manager/register-employee', {
          'username': _u.text.trim(),
          'email':    _e.text.trim(),
          'password': _p.text,
          if (_ph.text.trim().isNotEmpty)   'phone':   _ph.text.trim(),
          if (_addr.text.trim().isNotEmpty) 'address': _addr.text.trim(),
        });
      } else {
        final body = <String, String>{
          'username': _u.text.trim(),
          'email':    _e.text.trim(),
          if (_ph.text.trim().isNotEmpty)   'phone':   _ph.text.trim(),
          if (_addr.text.trim().isNotEmpty) 'address': _addr.text.trim(),
        };
        if (_p.text.isNotEmpty) body['password'] = _p.text;
        await AdminClient.put(
            '/manager/update-employee/${_editTarget!['id']}', body);
      }
      if (!mounted) return;
      setState(() { _showCreate = false; _editTarget = null; });
      _fetch();
    } catch (e) {
      if (mounted) { setState(() => _apiError = AdminClient.errorMessage(e)); }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await AdminClient.delete(
          '/manager/delete-employee/${_deleteTarget!['id']}');
      if (!mounted) return;
      setState(() => _deleteTarget = null);
      _fetch();
    } catch (_) {
      if (mounted) setState(() => _deleteTarget = null);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _assign() async {
    setState(() { _assigning = true; _assignError = null; });
    try {
      final empId     = _assignTarget!['id'];
      final terrainId = _assignTerrainId;
      if (terrainId != null) {
        await AdminClient.post(
            '/manager/assign-employee/$empId/terrain/$terrainId', null);
      }
      if (!mounted) return;
      setState(() { _assignTarget = null; _assignTerrainId = null; });
      _showMsg('Terrain assigned successfully.');
      _fetch();
    } catch (e) {
      if (mounted) { setState(() => _assignError = AdminClient.errorMessage(e)); }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: TextStyle(
                color: isError ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600)),
        backgroundColor:
            isError ? AdminColors.danger : AdminColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  @override
  Widget build(BuildContext context) {
    final ext      = context.adminExt;
    final filtered = _filtered;

    return Stack(children: [
      Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            AdminPageHeader(
              title:    'Employees',
              subtitle: 'Manage terrain staff and their assignments',
              onAdd:    _openCreate,
              addLabel: 'Register Employee',
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(color: ext.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText:  'Search by name or email…',
                  hintStyle: TextStyle(color: ext.subtle),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: ext.subtle),
                  filled:    true,
                  fillColor: ext.card,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: ext.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: ext.border)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                          color: AdminColors.indigo, width: 1.5)),
                ),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AdminColors.neonGreen))
              : _error != null
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline,
                            color: AdminColors.danger, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: AdminColors.danger, fontSize: 13)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetch,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.indigo,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10))),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ]))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.badge_outlined,
                                color: ext.subtle, size: 48),
                            const SizedBox(height: 14),
                            Text(
                                _search.isNotEmpty
                                    ? 'No results for "$_search".'
                                    : 'No employees yet.',
                                style:
                                    TextStyle(color: ext.muted)),
                          ]))
                      : RefreshIndicator(
                          color: AdminColors.neonGreen,
                          onRefresh: _fetch,
                          child: ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(32, 0, 32, 40),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _EmployeeCard(
                              emp:      filtered[i],
                              ext:      ext,
                              onEdit:   () => _openEdit(filtered[i]),
                              onDelete: () => setState(
                                  () => _deleteTarget = filtered[i]),
                              onAssign: () => setState(() {
                                _assignTarget    = filtered[i];
                                _assignTerrainId = null;
                                _assignCampusId  = null;
                                _assignError     = null;
                              }),
                            ),
                          ),
                        ),
        ),
      ]),

      // ── Create / Edit ────────────────────────────────────────────────────
      if (_showCreate)
        CrudModal(
          title: _editTarget == null
              ? 'Register Employee'
              : 'Edit Employee',
          onClose: () =>
              setState(() { _showCreate = false; _editTarget = null; }),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_apiError != null) ...[
              ModalErrorBanner(message: _apiError!),
              const SizedBox(height: 14),
            ],
            ModalField(
                label: 'Username', controller: _u, hint: 'employee_name'),
            const SizedBox(height: 12),
            ModalField(
                label: 'Email',
                controller: _e,
                hint: 'employee@example.com',
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            ModalField(
              label: _editTarget != null
                  ? 'New Password (leave blank to keep)'
                  : 'Password',
              controller: _p,
              hint:     '••••••••',
              obscure:  true,
              optional: _editTarget != null,
            ),
            const SizedBox(height: 12),
            ModalField(
                label: 'Phone',
                controller: _ph,
                hint: 'Optional',
                type: TextInputType.phone,
                optional: true),
            const SizedBox(height: 12),
            ModalField(
                label: 'Address',
                controller: _addr,
                hint: 'Optional',
                optional: true),
            const SizedBox(height: 20),
            ModalActions(
              onCancel: () => setState(
                  () { _showCreate = false; _editTarget = null; }),
              onSave:  _save,
              saving:  _saving,
            ),
          ]),
        ),

      // ── Delete ───────────────────────────────────────────────────────────
      if (_deleteTarget != null)
        DeleteModal(
          title:       'Delete Employee',
          description: 'Delete "${_deleteTarget!['email']}"? This cannot be undone.',
          onConfirm:   _delete,
          onCancel:    () => setState(() => _deleteTarget = null),
          deleting:    _deleting,
        ),

      // ── Assign terrain ───────────────────────────────────────────────────
      if (_assignTarget != null)
        CrudModal(
          title:   'Assign Terrain — ${_assignTarget!['username']}',
          onClose: () => setState(() {
            _assignTarget = null; _assignTerrainId = null; _assignCampusId = null;
          }),
          child: StatefulBuilder(builder: (ctx, setSt) {
            final e2 = ctx.adminExt;

            // Unique campuses from terrain list
            final campusMap = <int, String>{};
            for (final t in _terrains) {
              final c = t['campus'] as Map?;
              if (c != null && c['id'] != null) {
                campusMap[c['id'] as int] = c['Name']?.toString() ?? 'Campus';
              }
            }
            final campuses = campusMap.entries.toList();

            // Terrains filtered by selected campus
            final visTerrains = _assignCampusId == null
                ? _terrains
                : _terrains.where((t) {
                    final c = t['campus'] as Map?;
                    return c?['id'] == _assignCampusId;
                  }).toList();

            return Column(mainAxisSize: MainAxisSize.min, children: [
              if (_assignError != null) ...[
                ModalErrorBanner(message: _assignError!),
                const SizedBox(height: 14),
              ],

              // Campus filter
              if (campuses.length > 1) ...[
                Text('Campus', style: TextStyle(color: e2.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: e2.input,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: e2.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _assignCampusId,
                      isExpanded: true,
                      dropdownColor: e2.card,
                      hint: Text('All campuses', style: TextStyle(color: e2.subtle, fontSize: 14)),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All campuses', style: TextStyle(color: e2.text, fontSize: 14)),
                        ),
                        ...campuses.map((entry) => DropdownMenuItem<int?>(
                          value: entry.key,
                          child: Text(entry.value, style: TextStyle(color: e2.text, fontSize: 14)),
                        )),
                      ],
                      onChanged: (v) => setSt(() {
                        _assignCampusId  = v;
                        _assignTerrainId = null; // reset terrain on campus change
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              Text('Select a terrain:', style: TextStyle(color: e2.muted, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),

              // Terrain list — constrained height to prevent overflow
              if (visTerrains.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No terrains available for this campus.',
                      style: TextStyle(color: e2.subtle, fontSize: 13)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min,
                          children: visTerrains.map((t) {
                        final tId  = t['id'] as int?;
                        final type = (t['Type'] ?? t['type'] ?? '—').toString();
                        final camp = (t['campus'] as Map?)?['Name']?.toString() ?? '';
                        final sel  = _assignTerrainId == tId;
                        return GestureDetector(
                          onTap: () => setSt(() => _assignTerrainId = tId),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color:        sel ? AdminColors.neonGreen.withValues(alpha: 0.12) : e2.input,
                              borderRadius: BorderRadius.circular(10),
                              border:       Border.all(
                                color: sel ? AdminColors.neonGreen : e2.border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Icon(Icons.sports_soccer_outlined, size: 16,
                                  color: sel ? AdminColors.neonGreen : e2.muted),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(type, style: TextStyle(
                                    color: sel ? AdminColors.neonGreen : e2.text,
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                                if (camp.isNotEmpty)
                                  Text(camp, style: TextStyle(color: e2.muted, fontSize: 11)),
                              ])),
                              if (sel) const Icon(Icons.check_circle, color: AdminColors.neonGreen, size: 18),
                            ]),
                          ),
                        );
                      }).toList()),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              ModalActions(
                onCancel: () => setState(
                    () { _assignTarget = null; _assignTerrainId = null; }),
                onSave:    _assign,
                saving:    _assigning,
                saveLabel: 'Assign',
              ),
            ]);
          }),
        ),
    ]);
  }
}

// ─── Employee card ────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.emp,
    required this.ext,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
  });
  final Map<String, dynamic> emp;
  final AdminExt ext;
  final VoidCallback onEdit, onDelete, onAssign;

  @override
  Widget build(BuildContext context) {
    final name     = emp['username']?.toString() ?? '—';
    final email    = emp['email']?.toString()    ?? '';
    final phone    = emp['phone']?.toString();
    final terrain  = emp['terrain'];
    final tId      = terrain is Map ? terrain['id'] : terrain;
    final assigned = tId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ext.card,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: ext.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: AdminColors.indigo.withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AdminColors.indigo,
                fontSize: 15,
                fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: TextStyle(
                    color: ext.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(email, style: TextStyle(color: ext.muted, fontSize: 12)),
            if (phone != null && phone.isNotEmpty)
              Text(phone,
                  style: TextStyle(color: ext.subtle, fontSize: 11)),
            const SizedBox(height: 8),

            // Terrain assignment
            assigned
                ? Wrap(crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AdminColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AdminColors.teal
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.sports_soccer_outlined,
                            size: 11, color: AdminColors.teal),
                        const SizedBox(width: 4),
                        Text('Terrain #$tId',
                            style: const TextStyle(
                                color: AdminColors.teal,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: onAssign,
                      child: Text('Change',
                          style: TextStyle(
                              color: ext.muted,
                              fontSize: 11,
                              decoration: TextDecoration.underline)),
                    ),
                  ])
                : GestureDetector(
                    onTap: onAssign,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AdminColors.warning.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AdminColors.warning
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(Icons.add_circle_outline,
                            size: 13, color: AdminColors.warning),
                        SizedBox(width: 5),
                        Text('Assign Terrain',
                            style: TextStyle(
                                color: AdminColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
          ]),
        ),

        // Edit / Delete
        Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 17, color: ext.muted),
            tooltip: 'Edit',
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 17, color: AdminColors.danger),
            tooltip: 'Delete',
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ]),
      ]),
    );
  }
}
