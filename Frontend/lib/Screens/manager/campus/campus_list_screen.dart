import 'package:Arena/models/models.dart';
import 'package:Arena/Screens/manager/campus/campus_detail_screen.dart';
import 'package:Arena/Screens/manager/campus/create_campus_screen.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ManagerCampusScreen extends StatefulWidget {
  const ManagerCampusScreen({super.key});

  @override
  State<ManagerCampusScreen> createState() => _ManagerCampusScreenState();
}

class _ManagerCampusScreenState extends State<ManagerCampusScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CampusProvider>().loadMine(context.read<CampusService>());
  }

  Future<void> _refresh() =>
      context.read<CampusProvider>().refreshMine(context.read<CampusService>());

  void _openCreateCampus() async {
    final campusProv = context.read<CampusProvider>();
    final campusSvc  = context.read<CampusService>();
    final created    = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCampusScreen()),
    );
    if (created == true && mounted) campusProv.refreshMine(campusSvc);
  }

  void _openCampus(Campus campus) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CampusDetailScreen(campus: campus)),
    );
    if (changed == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CampusProvider>();
    final campuses = provider.campuses;
    final hPad     = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('My Campuses',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  if (!provider.isLoading) ...[
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _refresh,
                        child: const SizedBox(
                          width: 46, height: 46,
                          child: Center(
                            child: FaIcon(FontAwesomeIcons.arrowsRotate,
                                color: AppColors.textPrimary, size: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: AppColors.neonGreen,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openCreateCampus,
                        child: const SizedBox(
                          width: 46, height: 46,
                          child: Center(
                            child: FaIcon(FontAwesomeIcons.plus,
                                color: Colors.black, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.neonGreen))
                  : provider.error != null
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const FaIcon(FontAwesomeIcons.triangleExclamation,
                                color: Colors.redAccent, size: 36),
                            const SizedBox(height: 14),
                            Text(provider.error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _refresh,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Retry',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ),
                            ),
                          ]))
                      : campuses.isEmpty
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const FaIcon(FontAwesomeIcons.building,
                                    color: AppColors.textSecondary, size: 40),
                                const SizedBox(height: 14),
                                Text('No campuses found.',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary, fontSize: 14)),
                              ]))
                          : RefreshIndicator(
                              color: AppColors.neonGreen,
                              onRefresh: _refresh,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                                itemCount: campuses.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 14),
                                itemBuilder: (_, i) => _CampusCard(
                                  campus: campuses[i],
                                  onTap: () => _openCampus(campuses[i]),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Campus card ──────────────────────────────────────────────────────────────

class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.campus, required this.onTap});
  final Campus campus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = campus.mainImage?.fullUrl;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────
            SizedBox(
              height: 140,
              width: double.infinity,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl, fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null ? child
                          : Container(color: AppColors.surfaceVariant,
                              child: const Center(child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.neonGreen))),
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            // ── Info ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campus.name,
                      style: GoogleFonts.montserrat(
                          color: AppColors.textPrimary,
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.locationDot,
                          color: AppColors.textSecondary, size: 11),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(campus.address,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Badge(
                        icon: FontAwesomeIcons.trophy,
                        label: '${campus.nbTerrains} terrains',
                      ),
                      if (campus.phone != null) ...[
                        const SizedBox(width: 10),
                        _Badge(
                          icon: FontAwesomeIcons.phone,
                          label: campus.phone!,
                        ),
                      ],
                      const Spacer(),
                      const FaIcon(FontAwesomeIcons.chevronRight,
                          color: AppColors.textSecondary, size: 11),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: FaIcon(FontAwesomeIcons.building,
              color: Color.fromRGBO(255, 255, 255, 0.15), size: 48),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  final dynamic icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: AppColors.neonGreen, size: 11),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.neonGreen,
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      );
}
