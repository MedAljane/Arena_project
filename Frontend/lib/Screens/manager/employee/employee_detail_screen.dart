import 'package:Arena/models/models.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  // ── Edit fields ────────────────────────────────────────────────────────────
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  bool _savingProfile = false;

  // ── Terrain assignment ─────────────────────────────────────────────────────
  List<Terrain> _terrains      = [];
  Terrain?      _selectedTerrain;
  bool _loadingTerrains = true;
  bool _assigningTerrain = false;

  // ── Delete ─────────────────────────────────────────────────────────────────
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _usernameCtrl = TextEditingController(text: e.username);
    _emailCtrl    = TextEditingController(text: e.email);
    _addressCtrl  = TextEditingController(text: e.address ?? '');
    _phoneCtrl    = TextEditingController(text: e.phone   ?? '');
    _fetchTerrains();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTerrains() async {
    try {
      final list = await context.read<TerrainService>().getManagerTerrains();
      // Pre-select the terrain this employee is currently assigned to.
      final current = list.cast<Terrain?>().firstWhere(
        (t) => t?.id == widget.employee.terrain,
        orElse: () => null,
      );
      if (mounted) {
        setState(() {
          _terrains         = list;
          _selectedTerrain  = current;
          _loadingTerrains  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTerrains = false);
    }
  }

  // ── Save profile ───────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final username = _usernameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    if (username.isEmpty || email.isEmpty) {
      _showMsg('Username and email cannot be empty.', isError: true);
      return;
    }

    setState(() => _savingProfile = true);
    try {
      await context.read<EmployeeService>().updateEmployee(
        widget.employee.id,
        UpdateEmployeeRequest(
          username: username,
          email:    email,
          address:  _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          phone:    _phoneCtrl.text.trim().isEmpty   ? null : _phoneCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      _showMsg('Profile updated!');
      Navigator.pop(context, 'updated');
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (e) {
      _showMsg('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  // ── Assign terrain ─────────────────────────────────────────────────────────
  Future<void> _assignTerrain() async {
    if (_selectedTerrain == null) {
      _showMsg('Select a terrain first.', isError: true);
      return;
    }
    setState(() => _assigningTerrain = true);
    try {
      await context.read<EmployeeService>().assignEmployee(
        employeeId: widget.employee.id,
        terrainId:  _selectedTerrain!.id,
      );
      if (!mounted) return;
      _showMsg('Assigned to ${_selectedTerrain!.type.name}!');
      Navigator.pop(context, 'updated');
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (e) {
      _showMsg('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _assigningTerrain = false);
    }
  }

  // ── Delete employee ────────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Employee',
            style: GoogleFonts.montserrat(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${widget.employee.username}"?\n'
          'This will also delete their user account.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
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

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<EmployeeService>().deleteEmployee(widget.employee.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.employee.username} deleted.',
            style: GoogleFonts.inter(
                color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context, 'deleted');
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (e) {
      _showMsg('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
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

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;
    final e    = widget.employee;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
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
                        child: Center(
                          child: FaIcon(FontAwesomeIcons.arrowLeft,
                              color: AppColors.textPrimary, size: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(e.username,
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + status ────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                const Color.fromRGBO(46, 204, 113, 0.15),
                            child: Text(
                              e.username.isNotEmpty
                                  ? e.username[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.neonGreen,
                                  fontWeight: FontWeight.w800, fontSize: 26),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: e.terrain != null
                                  ? const Color.fromRGBO(46, 204, 113, 0.12)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: e.terrain != null
                                    ? AppColors.neonGreen.withValues(alpha: 0.4)
                                    : AppColors.divider,
                              ),
                            ),
                            child: Text(
                              e.terrain != null
                                  ? 'Assigned to terrain #${e.terrain}'
                                  : 'Unassigned',
                              style: GoogleFonts.inter(
                                  color: e.terrain != null
                                      ? AppColors.neonGreen
                                      : AppColors.textSecondary,
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Section 1: Edit Profile ────────────────────────────
                    _SectionHeader('Edit Profile'),
                    const SizedBox(height: 12),
                    _EditField(label: 'Username',      controller: _usernameCtrl),
                    const SizedBox(height: 12),
                    _EditField(label: 'Email',         controller: _emailCtrl,   keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _EditField(label: 'Address',       controller: _addressCtrl, hint: 'Optional'),
                    const SizedBox(height: 12),
                    _EditField(label: 'Phone',         controller: _phoneCtrl,   hint: 'Optional', keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _savingProfile
                        ? const Center(child: CircularProgressIndicator(
                              color: AppColors.neonGreen, strokeWidth: 2))
                        : SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AppColors.neonGreen,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _saveProfile,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text('SAVE CHANGES',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 28),

                    // ── Section 2: Terrain Assignment ─────────────────────
                    _SectionHeader('Terrain Assignment'),
                    const SizedBox(height: 12),
                    if (_loadingTerrains)
                      const Center(child: CircularProgressIndicator(
                          color: AppColors.neonGreen, strokeWidth: 2))
                    else ...[
                      _TerrainDropdown(
                        terrains: _terrains,
                        selected: _selectedTerrain,
                        onChanged: (t) => setState(() => _selectedTerrain = t),
                      ),
                      const SizedBox(height: 12),
                      _assigningTerrain
                          ? const Center(child: CircularProgressIndicator(
                                color: AppColors.neonGreen, strokeWidth: 2))
                          : SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _assignTerrain,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const FaIcon(
                                            FontAwesomeIcons.locationArrow,
                                            color: AppColors.neonGreen,
                                            size: 13),
                                        const SizedBox(width: 8),
                                        Text('ASSIGN TERRAIN',
                                            style: GoogleFonts.montserrat(
                                                color: AppColors.neonGreen,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                    const SizedBox(height: 28),

                    // ── Section 3: Danger Zone ────────────────────────────
                    _SectionHeader('Danger Zone', danger: true),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete "${e.username}"',
                            style: GoogleFonts.inter(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Permanently deletes the employee profile and their user account.',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          _deleting
                              ? const Center(child: CircularProgressIndicator(
                                    color: Colors.redAccent, strokeWidth: 2))
                              : Material(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: _confirmDelete,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Text('Delete Employee',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.danger = false});
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.montserrat(
          color: danger ? Colors.redAccent : AppColors.textPrimary,
          fontSize: 15, fontWeight: FontWeight.w700));
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.hint = '',
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11.5,
                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color.fromRGBO(46, 204, 113, 0.35)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      );
}

class _TerrainDropdown extends StatelessWidget {
  const _TerrainDropdown({
    required this.terrains,
    required this.selected,
    required this.onChanged,
  });
  final List<Terrain> terrains;
  final Terrain? selected;
  final ValueChanged<Terrain?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color.fromRGBO(46, 204, 113, 0.35)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Terrain?>(
            value: selected,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 14),
            hint: Text('Select terrain',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14)),
            items: terrains
                .map((t) => DropdownMenuItem<Terrain?>(
                      value: t,
                      child: Text(
                        '${t.type.name}  (ID ${t.id})',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}
