import 'package:Arena/models/models.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  // ── Form controllers ───────────────────────────────────────────────────────
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  bool _hidePassword  = true;

  // ── Terrain dropdown ───────────────────────────────────────────────────────
  List<Terrain> _terrains      = [];
  Terrain?      _selectedTerrain;
  bool          _loadingTerrains = true;

  // ── Submit state ──────────────────────────────────────────────────────────
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchTerrains();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTerrains() async {
    try {
      final list = await context.read<TerrainService>().getManagerTerrains();
      if (mounted) setState(() { _terrains = list; _loadingTerrains = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTerrains = false);
    }
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final address  = _addressCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMsg('Username, email and password are required.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<EmployeeService>().registerEmployee(
        RegisterEmployeeRequest(
          username: username,
          email:    email,
          password: password,
          address:  address.isEmpty ? null : address,
          phone:    phone.isEmpty   ? null : phone,
          terrainId: _selectedTerrain?.id,
        ),
      );
      if (!mounted) return;
      _showMsg('Employee registered successfully!');
      Navigator.pop(context, true); // signal list to refresh
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (e) {
      _showMsg('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    child: Text('Register Employee',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Form ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Required section
                    _SectionLabel('Account Info'),
                    const SizedBox(height: 12),
                    _Field(label: 'Username *',  controller: _usernameCtrl, hint: 'john_doe'),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Email *',
                      controller: _emailCtrl,
                      hint: 'employee@arena.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      label: 'Password *',
                      controller: _passwordCtrl,
                      obscure: _hidePassword,
                      onToggle: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                    const SizedBox(height: 24),

                    // Optional section
                    _SectionLabel('Additional Info'),
                    const SizedBox(height: 12),
                    _Field(label: 'Address',      controller: _addressCtrl, hint: 'Optional'),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Phone',
                      controller: _phoneCtrl,
                      hint: 'Optional',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Terrain assignment section
                    _SectionLabel('Terrain Assignment'),
                    const SizedBox(height: 4),
                    Text('Assign the employee to a terrain right away (optional).',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    _loadingTerrains
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.neonGreen, strokeWidth: 2))
                        : _TerrainDropdown(
                            terrains: _terrains,
                            selected: _selectedTerrain,
                            onChanged: (t) => setState(() => _selectedTerrain = t),
                          ),
                    const SizedBox(height: 32),

                    // Submit
                    _loading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.neonGreen))
                        : SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AppColors.neonGreen,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _submit,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text('REGISTER EMPLOYEE',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ),
                              ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.montserrat(
          color: AppColors.textPrimary,
          fontSize: 15, fontWeight: FontWeight.w700));
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

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
              obscureText: obscure,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: InputBorder.none,
                suffixIcon: GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary, size: 20,
                  ),
                ),
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
          border: Border.all(color: const Color.fromRGBO(46, 204, 113, 0.35)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Terrain?>(
            value: selected,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 14),
            hint: Text('No terrain assigned',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14)),
            items: [
              DropdownMenuItem<Terrain?>(
                value: null,
                child: Text('No terrain',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
              ...terrains.map((t) => DropdownMenuItem<Terrain?>(
                    value: t,
                    child: Text(
                      '${t.type.name}  (ID ${t.id})',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 14),
                    ),
                  )),
            ],
            onChanged: onChanged,
          ),
        ),
      );
}
