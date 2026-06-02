import 'package:Arena/models/models.dart';
import 'package:Arena/Screens/player/terrain_availability_screen.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CampusTerrainsScreen extends StatefulWidget {
  final Campus campus;

  const CampusTerrainsScreen({super.key, required this.campus});

  @override
  State<CampusTerrainsScreen> createState() => _CampusTerrainsScreenState();
}

class _CampusTerrainsScreenState extends State<CampusTerrainsScreen> {
  List<Terrain> _terrains = [];
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final all = await context.read<TerrainService>().getPlayerTerrains();
      // Keep only terrains that belong to this campus.
      final filtered = all.where((t) => t.campus?.id == widget.campus.id).toList();
      if (mounted) setState(() { _terrains = filtered; _loading = false; });
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
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
    final c    = widget.campus;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.locationDot,
                                color: AppColors.textSecondary, size: 10),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(c.address,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 20),

            // ── Terrain list ──────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                        color: AppColors.neonGreen))
                  : _error != null
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error!,
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () { setState(() { _loading = true; _error = null; }); _fetch(); },
                            child: Text('Retry', style: GoogleFonts.inter(
                                color: AppColors.neonGreen, fontSize: 13,
                                fontWeight: FontWeight.w600)),
                          ),
                        ]))
                      : _terrains.isEmpty
                          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const FaIcon(FontAwesomeIcons.trophy,
                                  color: AppColors.textSecondary, size: 40),
                              const SizedBox(height: 14),
                              Text('No terrains available.',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary, fontSize: 14)),
                            ]))
                          : RefreshIndicator(
                              color: AppColors.neonGreen,
                              onRefresh: _fetch,
                              child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                              itemCount: _terrains.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final t = _terrains[i];
                                final publishedCount = t.weekAgenda
                                    .where((a) => a.statu == WeekAgendaStatus.Published)
                                    .length;
                                return Material(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TerrainAvailabilityScreen(
                                          terrain: t,
                                          campus:  widget.campus,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 52, height: 52,
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(46, 204, 113, 0.10),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Center(
                                              child: FaIcon(_iconFor(t.type),
                                                  color: AppColors.neonGreen, size: 22),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(t.type.name,
                                                    style: GoogleFonts.montserrat(
                                                        color: AppColors.textPrimary,
                                                        fontSize: 16, fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 4),
                                                Row(children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: publishedCount > 0
                                                          ? const Color.fromRGBO(46, 204, 113, 0.12)
                                                          : AppColors.surfaceVariant,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      publishedCount > 0
                                                          ? '$publishedCount week${publishedCount > 1 ? 's' : ''} available'
                                                          : 'No schedule',
                                                      style: GoogleFonts.inter(
                                                          color: publishedCount > 0
                                                              ? AppColors.neonGreen
                                                              : AppColors.textSecondary,
                                                          fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ]),
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
                              },
                            ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
