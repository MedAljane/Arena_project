import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/providers/admin_auth_provider.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/crud_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerProfileWebScreen extends StatefulWidget {
  const ManagerProfileWebScreen({super.key});
  @override
  State<ManagerProfileWebScreen> createState() => _ManagerProfileWebScreenState();
}

class _ManagerProfileWebScreenState extends State<ManagerProfileWebScreen> {
  bool    _loading  = true;
  String? _error;
  bool    _editing  = false;
  bool    _saving   = false;
  String? _saveError;

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _fetch(); }
  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r    = await AdminClient.get('/manager/me');
      final data = r.data as Map<String, dynamic>;
      if (mounted) {
        setState(() => _loading = false);
        _nameCtrl.text    = data['nom']     ?? (data['user'] as Map?)?['username'] ?? '';
        _emailCtrl.text   = (data['user'] as Map?)?['email'] ?? '';
        _phoneCtrl.text   = data['phone']   ?? '';
        _addressCtrl.text = data['address'] ?? '';
      }
    } catch (e) {
      if (mounted) setState(() { _error = AdminClient.errorMessage(e); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _saveError = null; });
    try {
      await AdminClient.put('/manager/me', {
        'username': _nameCtrl.text.trim(),
        'email':    _emailCtrl.text.trim(),
        'phone':    _phoneCtrl.text.trim(),
        'address':  _addressCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _editing = false);
      _fetch();
    } catch (e) {
      if (mounted) setState(() => _saveError = AdminClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext  = context.adminExt;
    final auth = context.watch<AdminAuthProvider>();
    final init = (auth.email?.isNotEmpty == true) ? auth.email![0].toUpperCase() : 'M';

    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Profile',
              style: TextStyle(color: ext.text, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Manage your account information',
              style: TextStyle(color: ext.muted, fontSize: 13)),
          const SizedBox(height: 32),

          if (_loading)
            const Center(child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(color: AdminColors.neonGreen)))
          else if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: AdminColors.danger)))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Avatar + name row ──────────────────────────────────────
                Row(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AdminColors.neonGreen.withValues(alpha: 0.15),
                    child: Text(init,
                        style: const TextStyle(
                            color: AdminColors.neonGreen,
                            fontSize: 28, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : auth.email ?? '—',
                        style: TextStyle(color: ext.text, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color:        AdminColors.neonGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AdminColors.neonGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Text('Manager',
                          style: TextStyle(
                              color: AdminColors.neonGreen,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ])),
                  ElevatedButton.icon(
                    onPressed: () => setState(() { _editing = true; _saveError = null; }),
                    icon:  const Icon(Icons.edit_outlined, size: 15, color: Colors.white),
                    label: const Text('Edit Profile',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ]),
                const SizedBox(height: 32),

                // ── Info card ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:        ext.card,
                    borderRadius: BorderRadius.circular(16),
                    border:       Border.all(color: ext.border),
                  ),
                  child: Column(children: [
                    _InfoRow(icon: Icons.person_outline, label: 'Name',
                        value: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : '—', ext: ext),
                    Divider(color: ext.border, height: 20),
                    _InfoRow(icon: Icons.email_outlined, label: 'Email',
                        value: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '—', ext: ext),
                    Divider(color: ext.border, height: 20),
                    _InfoRow(icon: Icons.phone_outlined, label: 'Phone',
                        value: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '—', ext: ext),
                    Divider(color: ext.border, height: 20),
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Address',
                        value: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : '—', ext: ext),
                  ]),
                ),
              ]),
            ),
        ]),
      ),

      // Edit modal
      if (_editing)
        CrudModal(
          title:   'Edit Profile',
          onClose: () => setState(() => _editing = false),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_saveError != null) ...[
              ModalErrorBanner(message: _saveError!), const SizedBox(height: 14)],
            ModalField(label: 'Name',    controller: _nameCtrl,    hint: 'Your name'),
            const SizedBox(height: 12),
            ModalField(label: 'Email',   controller: _emailCtrl,   hint: 'your@email.com',
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            ModalField(label: 'Phone',   controller: _phoneCtrl,   hint: 'Optional',
                type: TextInputType.phone, optional: true),
            const SizedBox(height: 12),
            ModalField(label: 'Address', controller: _addressCtrl, hint: 'Optional', optional: true),
            const SizedBox(height: 20),
            ModalActions(
              onCancel: () => setState(() => _editing = false),
              onSave:   _save,
              saving:   _saving,
            ),
          ]),
        ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon, required this.label,
    required this.value, required this.ext,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final AdminExt ext;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AdminColors.neonGreen, size: 15),
    const SizedBox(width: 12),
    Text('$label: ', style: TextStyle(color: ext.muted, fontSize: 14)),
    Expanded(
      child: Text(value,
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: ext.text, fontSize: 14, fontWeight: FontWeight.w500)),
    ),
  ]);
}
