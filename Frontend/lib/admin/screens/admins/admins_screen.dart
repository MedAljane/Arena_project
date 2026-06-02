import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/widgets/admin_data_table.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:Arena/admin/widgets/crud_modal.dart';
import 'package:flutter/material.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});
  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  List<Map<String, dynamic>> _rows    = [];
  bool    _loading = true;
  String? _error;
  Map<String, dynamic>? _editTarget;
  bool _showCreate = false;
  bool _saving     = false;
  String? _apiError;
  Map<String, dynamic>? _deleteTarget;
  bool _deleting   = false;

  final _u = TextEditingController();
  final _e = TextEditingController();
  final _p = TextEditingController();

  @override
  void initState() { super.initState(); _fetch(); }
  @override
  void dispose() { _u.dispose(); _e.dispose(); _p.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await AdminClient.get('/admin/admins');
      final data = r.data;
      final list = data is List ? data : (data['result'] as List? ?? []);
      if (mounted) {
        setState(() {
          _rows    = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openCreate() {
    _u.clear(); _e.clear(); _p.clear();
    setState(() { _editTarget = null; _showCreate = true; _apiError = null; });
  }

  void _openEdit(Map<String, dynamic> row) {
    _u.text = row['username'] ?? '';
    _e.text = row['email']    ?? '';
    _p.clear();
    setState(() { _editTarget = row; _showCreate = true; _apiError = null; });
  }

  Future<void> _save() async {
    setState(() { _saving = true; _apiError = null; });
    try {
      if (_editTarget == null) {
        await AdminClient.post('/admin/register-admin', {
          'username': _u.text.trim(),
          'email':    _e.text.trim(),
          'password': _p.text,
        });
      } else {
        final body = {
          'username': _u.text.trim(),
          'email':    _e.text.trim(),
        };
        if (_p.text.isNotEmpty) body['password'] = _p.text;
        await AdminClient.put('/admin/update-admin/${_editTarget!['id']}', body);
      }
      if (!mounted) return;
      setState(() { _showCreate = false; _editTarget = null; });
      _fetch();
    } catch (e) {
      if (mounted) setState(() => _apiError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await AdminClient.delete('/admin/delete-admin/${_deleteTarget!['id']}');
      if (!mounted) return;
      setState(() { _deleteTarget = null; });
      _fetch();
    } catch (e) {
      if (mounted) setState(() { _deleteTarget = null; });
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title:    'Admins',
                subtitle: 'Manage administrator accounts',
                onAdd:    _openCreate,
                addLabel: 'New Admin',
              ),
              const SizedBox(height: 20),
              AdminDataTable(
                columns: const [
                  AdminColumn('id',       'ID',       mono: true),
                  AdminColumn('username', 'Username', flex: 2),
                  AdminColumn('email',    'Email',    flex: 3),
                ],
                rows:         _rows,
                loading:      _loading,
                error:        _error,
                emptyLabel:   'No admins found.',
                searchFields: const ['username', 'email'],
                onEdit:       _openEdit,
                onDelete:     (row) => setState(() => _deleteTarget = row),
              ),
            ],
          ),
        ),

        // Create / Edit modal
        if (_showCreate)
          CrudModal(
            title:   _editTarget == null ? 'New Admin' : 'Edit Admin',
            onClose: () => setState(() { _showCreate = false; _editTarget = null; }),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_apiError != null) ...[
                  ModalErrorBanner(message: _apiError!),
                  const SizedBox(height: 14),
                ],
                ModalField(label: 'Username',  controller: _u, hint: 'admin_name'),
                const SizedBox(height: 12),
                ModalField(label: 'Email',     controller: _e, hint: 'admin@example.com', type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                ModalField(
                  label:    _editTarget != null ? 'New Password (leave blank to keep)' : 'Password',
                  controller: _p,
                  hint:     '••••••••',
                  obscure:  true,
                  optional: _editTarget != null,
                ),
                const SizedBox(height: 20),
                ModalActions(
                  onCancel: () => setState(() { _showCreate = false; _editTarget = null; }),
                  onSave:   _save,
                  saving:   _saving,
                ),
              ],
            ),
          ),

        // Delete modal
        if (_deleteTarget != null)
          DeleteModal(
            title:       'Delete Admin',
            description: 'Are you sure you want to delete "${_deleteTarget!['email']}"? This cannot be undone.',
            onConfirm:   _delete,
            onCancel:    () => setState(() => _deleteTarget = null),
            deleting:    _deleting,
          ),
      ],
    );
  }
}

