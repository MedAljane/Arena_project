import 'package:Arena/models/models.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddTerrainScreen extends StatefulWidget {
  final int campusId;
  final List<Employee> employees;

  const AddTerrainScreen({
    super.key,
    required this.campusId,
    required this.employees,
  });

  @override
  State<AddTerrainScreen> createState() => _AddTerrainScreenState();
}

class _AddTerrainScreenState extends State<AddTerrainScreen> {
  TerrainType? _selectedType;
  Employee?    _selectedEmployee;
  bool         _loading = false;

  Future<void> _submit() async {
    if (_selectedType == null) {
      _showMsg('Please select a terrain type.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<TerrainService>().createTerrain(
        TerrainRequest(
          type:       _selectedType!,
          campusId:   widget.campusId,
          employeeId: _selectedEmployee?.id,
        ),
      );
      if (!mounted) return;
      _showMsg('Terrain created!');
      Navigator.pop(context, true);
    } on ServiceException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (e) {
      _showMsg('Error: $e', isError: true);
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
            // ── Top bar ────────────────────────────────────────────────
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
                    child: Text('Add Terrain',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Terrain type ───────────────────────────────────
                    _Label('Terrain Type *'),
                    const SizedBox(height: 8),
                    _Dropdown<TerrainType?>(
                      hint: 'Select type',
                      value: _selectedType,
                      items: TerrainType.values
                          .map((t) => DropdownMenuItem<TerrainType?>(
                                value: t,
                                child: Row(
                                  children: [
                                    FaIcon(_iconFor(t),
                                        color: AppColors.neonGreen, size: 14),
                                    const SizedBox(width: 10),
                                    Text(t.name,
                                        style: GoogleFonts.inter(
                                            color: AppColors.textPrimary,
                                            fontSize: 14)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                    ),
                    const SizedBox(height: 24),

                    // ── Employee assignment ────────────────────────────
                    _Label('Assign Employee'),
                    const SizedBox(height: 4),
                    Text('Optional — can be assigned later.',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    _Dropdown<Employee?>(
                      hint: 'No employee',
                      value: _selectedEmployee,
                      items: [
                        DropdownMenuItem<Employee?>(
                          value: null,
                          child: Text('No employee',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 14)),
                        ),
                        ...widget.employees.map((e) => DropdownMenuItem<Employee?>(
                              value: e,
                              child: Text(e.username,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 14)),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedEmployee = v),
                    ),
                    const SizedBox(height: 36),

                    // ── Submit ─────────────────────────────────────────
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  child: Text('CREATE TERRAIN',
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

  static dynamic _iconFor(TerrainType t) => switch (t) {
        TerrainType.Football   => FontAwesomeIcons.futbol,
        TerrainType.Basketball => FontAwesomeIcons.basketball,
        TerrainType.Paddel     => FontAwesomeIcons.tableTennisPaddleBall,
        TerrainType.Tennis     => FontAwesomeIcons.tableTennisPaddleBall,
      };
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: 11.5,
          fontWeight: FontWeight.w600, letterSpacing: 0.4));
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

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
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            hint: Text(hint,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14)),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}
