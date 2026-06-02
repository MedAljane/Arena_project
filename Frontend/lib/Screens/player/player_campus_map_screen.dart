import 'package:Arena/models/models.dart';
import 'package:Arena/Screens/player/campus_terrains_screen.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlayerCampusMapScreen extends StatefulWidget {
  const PlayerCampusMapScreen({super.key});

  @override
  State<PlayerCampusMapScreen> createState() => _PlayerCampusMapScreenState();
}

class _PlayerCampusMapScreenState extends State<PlayerCampusMapScreen> {
  List<Campus> _all = [];
  List<Campus> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final list = await context.read<CampusService>().getPlayerCampuses();
      if (mounted) setState(() { _all = list; _filtered = list; _loading = false; });
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Text('Campuses',
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const FaIcon(FontAwesomeIcons.magnifyingGlass, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search campuses...',
                          hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
                  : _error != null
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.redAccent, size: 36),
                            const SizedBox(height: 14),
                            Text(_error!, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () { setState(() { _loading = true; _error = null; }); _fetch(); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: AppColors.neonGreen, borderRadius: BorderRadius.circular(10)),
                                child: Text('Retry', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ),
                          ]),
                        )
                      : _filtered.isEmpty
                          ? Center(child: Text('No campuses found', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)))
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => _CampusTile(campus: _filtered[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampusTile extends StatelessWidget {
  const _CampusTile({required this.campus});
  final Campus campus;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CampusTerrainsScreen(campus: campus)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(46, 204, 113, 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: campus.mainImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(campus.mainImage!.fullUrl, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                  child: FaIcon(FontAwesomeIcons.building, color: AppColors.neonGreen, size: 20))),
                        )
                      : const Center(
                          child: FaIcon(FontAwesomeIcons.building, color: AppColors.neonGreen, size: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campus.name,
                          style: GoogleFonts.montserrat(
                              color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(campus.address,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.trophy, color: AppColors.neonGreen, size: 11),
                        const SizedBox(width: 4),
                        Text('${campus.nbTerrains} terrains',
                            style: GoogleFonts.inter(
                                color: AppColors.neonGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const FaIcon(FontAwesomeIcons.chevronRight, color: AppColors.textSecondary, size: 11),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
