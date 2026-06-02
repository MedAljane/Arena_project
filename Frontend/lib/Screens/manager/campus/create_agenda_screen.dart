import 'package:Arena/models/models.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateAgendaScreen extends StatefulWidget {
  final int campusId;
  final List<Terrain> terrains;

  const CreateAgendaScreen({
    super.key,
    required this.campusId,
    required this.terrains,
  });

  @override
  State<CreateAgendaScreen> createState() => _CreateAgendaScreenState();
}

class _CreateAgendaScreenState extends State<CreateAgendaScreen> {
  DateTime?  _weekStartDate;
  Terrain?   _selectedTerrain;
  bool       _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonGreen,
            onPrimary: Colors.black,
            surface: AppColors.surface,
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.background),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _weekStartDate = picked);
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _toIso(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_weekStartDate == null) {
      _showMsg('Please select a week start date.', isError: true);
      return;
    }
    if (_selectedTerrain == null) {
      _showMsg('Please select a terrain.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<WeekAgendaService>().createWeekAgenda(
        CreateWeekAgendaRequest(
          weekStartDate: _toIso(_weekStartDate!),
          campusId:     widget.campusId,
          terrainType:  _selectedTerrain!.type,
          terrainId:    _selectedTerrain!.id,
        ),
      );
      if (!mounted) return;
      _showMsg('Agenda created! 7 day plans generated.');
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
                    child: Text('Create Agenda',
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
                    // ── Info banner ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.neonGreen.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.circleInfo,
                              color: AppColors.neonGreen, size: 13),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Creating an agenda auto-generates 7 day plans '
                              'and default time slots for the selected terrain type.',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Week start date ────────────────────────────────
                    _Label('Week Start Date *'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color.fromRGBO(46, 204, 113, 0.35)),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.calendarDay,
                                color: AppColors.neonGreen, size: 14),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _weekStartDate != null
                                    ? _formatDate(_weekStartDate!)
                                    : 'Tap to select date',
                                style: GoogleFonts.inter(
                                    color: _weekStartDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 14),
                              ),
                            ),
                            const FaIcon(FontAwesomeIcons.chevronRight,
                                color: AppColors.textSecondary, size: 11),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Terrain selection ──────────────────────────────
                    _Label('Select Terrain *'),
                    const SizedBox(height: 4),
                    Text(
                      widget.terrains.isEmpty
                          ? 'No terrains in this campus yet. Add a terrain first.'
                          : 'Pick the specific terrain this agenda covers.',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (widget.terrains.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text('Add terrains to this campus first.',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color.fromRGBO(46, 204, 113, 0.35)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Terrain>(
                            value: _selectedTerrain,
                            isExpanded: true,
                            dropdownColor: AppColors.surface,
                            hint: Text('Select terrain',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                            items: widget.terrains
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        '${t.type.name}  (ID ${t.id})',
                                        style: GoogleFonts.inter(
                                            color: AppColors.textPrimary,
                                            fontSize: 14),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedTerrain = v),
                          ),
                        ),
                      ),
                    const SizedBox(height: 36),

                    // ── Submit ─────────────────────────────────────────
                    _loading
                        ? const Center(child: CircularProgressIndicator(
                              color: AppColors.neonGreen))
                        : SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: widget.terrains.isEmpty
                                  ? AppColors.surface
                                  : AppColors.neonGreen,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: widget.terrains.isEmpty ? null : _submit,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  child: Text('CREATE AGENDA',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                          color: widget.terrains.isEmpty
                                              ? AppColors.textSecondary
                                              : Colors.black,
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: 11.5,
          fontWeight: FontWeight.w600, letterSpacing: 0.4));
}
