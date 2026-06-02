import 'package:Arena/models/models.dart';
import 'package:Arena/Screens/manager/campus/add_terrain_screen.dart';
import 'package:Arena/Screens/manager/campus/create_agenda_screen.dart';
import 'package:Arena/Screens/manager/campus/terrain_detail_screen.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CampusDetailScreen extends StatefulWidget {
  final Campus campus;

  const CampusDetailScreen({super.key, required this.campus});

  @override
  State<CampusDetailScreen> createState() => _CampusDetailScreenState();
}

class _CampusDetailScreenState extends State<CampusDetailScreen> {
  Map<int, Employee> _empMap  = {};
  bool               _changed = false;
  String?            _error;

  @override
  void initState() {
    super.initState();
    // Terrains via provider — shared with AddTerrainScreen / CreateAgendaScreen.
    context.read<TerrainProvider>().loadForManager(context.read<TerrainService>());
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final employees = await context.read<EmployeeService>().getManagerEmployees();
      if (mounted) setState(() => _empMap = { for (final e in employees) e.id: e });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _refreshTerrains() {
    context.read<TerrainProvider>().refresh(context.read<TerrainService>());
  }

  String _employeeName(EmployeeSummary? summary) {
    if (summary == null) return 'Unassigned';
    final emp = _empMap[summary.id];
    return emp?.username ?? 'Employee #${summary.id}';
  }

  Future<void> _deleteCampus() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Campus',
            style: GoogleFonts.montserrat(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${widget.campus.name}"? This cannot be undone.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
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

    try {
      await context.read<CampusService>().deleteCampus(widget.campus.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _openAddTerrain() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTerrainScreen(
          campusId: widget.campus.id,
          employees: _empMap.values.toList(),
        ),
      ),
    );
    if (added == true) { _changed = true; _refreshTerrains(); }
  }

  void _openCreateAgenda() async {
    final terrains = context.read<TerrainProvider>().terrains
        .where((t) => t.campus?.id == widget.campus.id).toList();
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAgendaScreen(
          campusId: widget.campus.id,
          terrains: terrains,
        ),
      ),
    );
    if (created == true) { _changed = true; _refreshTerrains(); }
  }

  @override
  Widget build(BuildContext context) {
    final terrainProv = context.watch<TerrainProvider>();
    final terrains    = terrainProv.terrains
        .where((t) => t.campus?.id == widget.campus.id)
        .toList();
    final isLoading   = terrainProv.isLoading;
    final errorMsg    = terrainProv.error ?? _error;
    final hPad        = MediaQuery.of(context).size.width * 0.052;
    final c           = widget.campus;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
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
                        onTap: () => Navigator.pop(context, _changed),
                        child: const SizedBox(
                          width: 40, height: 40,
                          child: Center(
                            child: FaIcon(FontAwesomeIcons.arrowLeft,
                                color: AppColors.textPrimary, size: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(c.name,
                          style: GoogleFonts.montserrat(
                              color: AppColors.textPrimary,
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    Material(
                      color: const Color.fromRGBO(231, 76, 60, 0.15),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _deleteCampus,
                        child: const SizedBox(
                          width: 40, height: 40,
                          child: Center(
                            child: FaIcon(FontAwesomeIcons.trash,
                                color: Colors.redAccent, size: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonGreen))
                    : errorMsg != null
                        ? Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(errorMsg,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _refreshTerrains,
                                child: Text('Retry',
                                    style: GoogleFonts.inter(
                                        color: AppColors.neonGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]))
                        : RefreshIndicator(
                            color: AppColors.neonGreen,
                            onRefresh: () async {
                              _refreshTerrains();
                              await _fetchEmployees();
                            },
                            child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                EdgeInsets.fromLTRB(hPad, 0, hPad, 120),
                            children: [
                              // ── Campus image ─────────────────────────
                              if (c.mainImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 160, width: double.infinity,
                                    child: Image.network(
                                      c.mainImage!.fullUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          Container(
                                        color: AppColors.surfaceVariant,
                                        height: 160,
                                      ),
                                    ),
                                  ),
                                ),
                              if (c.mainImage != null) const SizedBox(height: 16),

                              // ── Campus info card ──────────────────────
                              _InfoCard(campus: c),
                              const SizedBox(height: 24),

                              // ── Terrains section ──────────────────────
                              Text('Terrains',
                                  style: GoogleFonts.montserrat(
                                      color: AppColors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              if (terrains.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Center(
                                    child: Text('No terrains yet.',
                                        style: GoogleFonts.inter(
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                  ),
                                )
                              else
                                ...terrains.map((t) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _TerrainTile(
                                        terrain: t,
                                        employeeName: _employeeName(t.employee),
                                        onTap: () async {
                                          final terrainProv = context.read<TerrainProvider>();
                                          final terrainSvc  = context.read<TerrainService>();
                                          final changed = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => TerrainDetailScreen(
                                                terrain: t,
                                                employeeName: _employeeName(t.employee),
                                                campusImage: widget.campus.mainImage?.fullUrl,
                                              ),
                                            ),
                                          );
                                          if (changed == true) {
                                            _changed = true;
                                            terrainProv.refresh(terrainSvc);
                                          }
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

        // ── Fixed action buttons ─────────────────────────────────────────
        bottomNavigationBar: isLoading
            ? null
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _openAddTerrain,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(FontAwesomeIcons.plus,
                                      color: AppColors.neonGreen, size: 13),
                                  const SizedBox(width: 8),
                                  Text('Add Terrain',
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: AppColors.neonGreen,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _openCreateAgenda,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(FontAwesomeIcons.calendarPlus,
                                      color: Colors.black, size: 13),
                                  const SizedBox(width: 8),
                                  Text('Create Agenda',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.campus});
  final Campus campus;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color.fromRGBO(46, 204, 113, 0.25)),
        ),
        child: Column(
          children: [
            _Row(icon: FontAwesomeIcons.locationDot, label: 'Address',
                value: campus.address),
            if (campus.phone != null) ...[
              const Divider(color: AppColors.divider, height: 20),
              _Row(icon: FontAwesomeIcons.phone, label: 'Phone',
                  value: campus.phone!),
            ],
            const Divider(color: AppColors.divider, height: 20),
            _Row(icon: FontAwesomeIcons.trophy, label: 'Terrains',
                value: '${campus.nbTerrains}'),
            if (campus.description != null) ...[
              const Divider(color: AppColors.divider, height: 20),
              _Row(icon: FontAwesomeIcons.circleInfo, label: 'About',
                  value: campus.description!),
            ],
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final dynamic icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: AppColors.neonGreen, size: 13),
          const SizedBox(width: 10),
          Text('$label: ',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

class _TerrainTile extends StatelessWidget {
  const _TerrainTile({
    required this.terrain,
    required this.employeeName,
    required this.onTap,
  });
  final Terrain terrain;
  final String employeeName;
  final VoidCallback onTap;

  static dynamic _iconFor(TerrainType t) => switch (t) {
        TerrainType.Football   => FontAwesomeIcons.futbol,
        TerrainType.Basketball => FontAwesomeIcons.basketball,
        TerrainType.Paddel     => FontAwesomeIcons.tableTennisPaddleBall,
        TerrainType.Tennis     => FontAwesomeIcons.tableTennisPaddleBall,
      };

  @override
  Widget build(BuildContext context) {
    final agendaCount = terrain.weekAgenda.length;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(46, 204, 113, 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FaIcon(_iconFor(terrain.type),
                  color: AppColors.neonGreen, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(terrain.type.name,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(employeeName,
                    style: GoogleFonts.inter(
                        color: employeeName == 'Unassigned'
                            ? AppColors.textSecondary
                            : AppColors.neonGreen,
                        fontSize: 12)),
              ],
            ),
          ),
          // Agenda count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: agendaCount > 0
                  ? const Color.fromRGBO(46, 204, 113, 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              agendaCount > 0 ? '$agendaCount agenda${agendaCount > 1 ? 's' : ''}' : 'No agendas',
              style: GoogleFonts.inter(
                  color: agendaCount > 0
                      ? AppColors.neonGreen
                      : AppColors.textSecondary,
                  fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),     // Row
    ),       // Container
  ),         // InkWell
);           // Material
  }
}
