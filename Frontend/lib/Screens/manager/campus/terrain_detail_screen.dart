import 'package:Arena/models/models.dart';
import 'package:Arena/Screens/manager/campus/agenda_detail_screen.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TerrainDetailScreen extends StatefulWidget {
  final Terrain terrain;
  final String employeeName;
  final String? campusImage; // campus image used as terrain header

  const TerrainDetailScreen({
    super.key,
    required this.terrain,
    required this.employeeName,
    this.campusImage,
  });

  @override
  State<TerrainDetailScreen> createState() => _TerrainDetailScreenState();
}

class _TerrainDetailScreenState extends State<TerrainDetailScreen> {
  late List<WeekAgendaSummary> _agendas;

  @override
  void initState() {
    super.initState();
    _agendas = List.from(widget.terrain.weekAgenda);
  }

  Future<void> _refresh() async {
    final terrainProv = context.read<TerrainProvider>();
    final terrainSvc  = context.read<TerrainService>();
    await terrainProv.refresh(terrainSvc);
    final updated = terrainProv.terrains
        .where((t) => t.id == widget.terrain.id)
        .firstOrNull;
    if (updated != null && mounted) {
      setState(() => _agendas = List.from(updated.weekAgenda));
    }
  }

  static dynamic _iconFor(TerrainType t) => switch (t) {
        TerrainType.Football   => FontAwesomeIcons.futbol,
        TerrainType.Basketball => FontAwesomeIcons.basketball,
        TerrainType.Paddel     => FontAwesomeIcons.tableTennisPaddleBall,
        TerrainType.Tennis     => FontAwesomeIcons.tableTennisPaddleBall,
      };

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;
    final t    = widget.terrain;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
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
                        child: Center(child: FaIcon(FontAwesomeIcons.arrowLeft,
                            color: AppColors.textPrimary, size: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${t.type.name} Terrain',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.neonGreen,
                onRefresh: _refresh,
                child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                children: [
                  // ── Hero image (campus image or type card) ──────────
                  if (widget.campusImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 150, width: double.infinity,
                        child: Image.network(
                          widget.campusImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _typeHero(t),
                        ),
                      ),
                    )
                  else
                    _typeHero(t),
                  const SizedBox(height: 20),

                  // ── Info card ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color.fromRGBO(46, 204, 113, 0.25)),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: _iconFor(t.type),
                          label: 'Type',
                          value: t.type.name,
                        ),
                        const Divider(color: AppColors.divider, height: 20),
                        _InfoRow(
                          icon: FontAwesomeIcons.userTie,
                          label: 'Employee',
                          value: widget.employeeName,
                          valueColor: widget.employeeName == 'Unassigned'
                              ? AppColors.textSecondary
                              : AppColors.neonGreen,
                        ),
                        if (t.campus != null) ...[
                          const Divider(color: AppColors.divider, height: 20),
                          _InfoRow(
                            icon: FontAwesomeIcons.building,
                            label: 'Campus',
                            value: t.campus!.name,
                          ),
                        ],
                        const Divider(color: AppColors.divider, height: 20),
                        _InfoRow(
                          icon: FontAwesomeIcons.calendarDays,
                          label: 'Agendas',
                          value: '${_agendas.length} week agenda${_agendas.length != 1 ? 's' : ''}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Agendas section ──────────────────────────────────
                  Text('Week Agendas',
                      style: GoogleFonts.montserrat(
                          color: AppColors.textPrimary,
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_agendas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Center(
                        child: Text('No agendas yet.',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    )
                  else
                    ..._agendas.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AgendaRow(
                            agenda: a,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AgendaDetailScreen(
                                    summary: a,
                                    terrainType: t.type,
                                  ),
                                ),
                              );
                              // Refresh local agenda statu if published
                              setState(() {});
                            },
                          ),
                        )),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeHero(Terrain t) => Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2A3A), Color(0xFF263B4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(_iconFor(t.type), color: AppColors.neonGreen, size: 48),
              const SizedBox(height: 10),
              Text(t.type.name,
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final dynamic icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          FaIcon(icon, color: AppColors.neonGreen, size: 13),
          const SizedBox(width: 10),
          Text('$label: ',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.agenda, required this.onTap});
  final WeekAgendaSummary agenda;
  final VoidCallback onTap;

  Color get _statusColor => switch (agenda.statu) {
        WeekAgendaStatus.Published => AppColors.neonGreen,
        WeekAgendaStatus.Draft     => const Color(0xFFFFC107),
      };

  String _fmtDate(String raw) {
    // raw = "YYYY-MM-DD"
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    final end = dt.add(const Duration(days: 6));
    return '${m[dt.month-1]} ${dt.day} – ${m[end.month-1]} ${end.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: FaIcon(FontAwesomeIcons.calendarDays,
                        color: _statusColor, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fmtDate(agenda.weekStartDate),
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(agenda.statu.name,
                            style: GoogleFonts.inter(
                                color: _statusColor,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const FaIcon(FontAwesomeIcons.chevronRight,
                    color: AppColors.textSecondary, size: 11),
              ],
            ),
          ),
        ),
      );
}
