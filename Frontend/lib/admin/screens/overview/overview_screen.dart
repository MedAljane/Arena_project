import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _loading = true;
  final Map<String, int> _counts = {};

  // AI quick stats
  Map<String, dynamic>? _aiStats;
  bool _aiLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _aiLoading = true; });
    try {
      final results = await Future.wait([
        AdminClient.get('/admin/admins'),
        AdminClient.get('/admin/managers'),
        AdminClient.get('/admin/players'),
        AdminClient.get('/admin/get-all-campuses'),
        AdminClient.get('/admin/employees'),
        AdminClient.get('/admin/terrains'),
        AdminClient.get('/admin/week-agendas'),
        AdminClient.get('/admin/ai-stats'),
      ]);

      int len(dynamic data, [String? key]) {
        if (data == null) return 0;
        if (data is List) return data.length;
        final map = data as Map<String, dynamic>;
        if (key != null && map[key] is List) return (map[key] as List).length;
        for (final v in map.values) { if (v is List) return v.length; }
        return 0;
      }

      if (mounted) {
        setState(() {
          _counts['admins']    = len(results[0].data, 'result');
          _counts['managers']  = len(results[1].data, 'result');
          _counts['players']   = len(results[2].data, 'result');
          _counts['campuses']  = len(results[3].data);
          _counts['employees'] = len(results[4].data, 'result');
          _counts['terrains']  = len(results[5].data, 'terrains');
          _counts['agendas']   = len(results[6].data, 'agendas');
          _loading             = false;
          _aiStats             = results[7].data as Map<String, dynamic>?;
          _aiLoading           = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _aiLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext  = context.adminExt;
    final w    = MediaQuery.of(context).size.width;
    final cols = w > 1200 ? 4 : (w > 800 ? 3 : 2);

    final aiOv   = (_aiStats?['overview']   as Map<String, dynamic>?) ?? {};
    final aiPerf = (_aiStats?['performance'] as Map<String, dynamic>?) ?? {};
    final aiConv = (_aiStats?['conversion']  as Map<String, dynamic>?) ?? {};

    return RefreshIndicator(
      color:     AdminColors.neonGreen,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Text('Overview',
                style: TextStyle(color: ext.text, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Platform summary at a glance',
                style: TextStyle(color: ext.muted, fontSize: 14)),
            const SizedBox(height: 28),

            // ── Platform stat grid ───────────────────────────────────────────
            GridView.count(
              crossAxisCount:   cols,
              crossAxisSpacing: 16,
              mainAxisSpacing:  16,
              childAspectRatio: 1.7,
              shrinkWrap:       true,
              physics:          const NeverScrollableScrollPhysics(),
              children: [
                StatCard(label: 'Admins',       value: '${_counts['admins']   ?? 0}', icon: Icons.shield_outlined,         color: AdminColors.indigo,  route: '/admin/dashboard/admins',       loading: _loading),
                StatCard(label: 'Managers',     value: '${_counts['managers'] ?? 0}', icon: Icons.manage_accounts_outlined, color: AdminColors.violet,  route: '/admin/dashboard/managers',     loading: _loading),
                StatCard(label: 'Players',      value: '${_counts['players']  ?? 0}', icon: Icons.person_outline,           color: AdminColors.sky,     route: '/admin/dashboard/players',      loading: _loading),
                StatCard(label: 'Campuses',     value: '${_counts['campuses'] ?? 0}', icon: Icons.location_city_outlined,   color: AdminColors.emerald, route: '/admin/dashboard/campuses',     loading: _loading),
                StatCard(label: 'Employees',    value: '${_counts['employees']?? 0}', icon: Icons.badge_outlined,           color: AdminColors.amber,   route: '/admin/dashboard/employees',    loading: _loading),
                StatCard(label: 'Terrains',     value: '${_counts['terrains'] ?? 0}', icon: Icons.sports_soccer_outlined,   color: AdminColors.teal,    route: '/admin/dashboard/terrains',     loading: _loading),
                StatCard(label: 'Week Agendas', value: '${_counts['agendas']  ?? 0}', icon: Icons.calendar_today_outlined,  color: AdminColors.rose,    route: '/admin/dashboard/week-agendas', loading: _loading),
              ],
            ),

            const SizedBox(height: 36),

            // ── AI Assistant section ─────────────────────────────────────────
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color:        AdminColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: AdminColors.neonGreen, size: 16),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Assistant',
                    style: TextStyle(color: ext.text, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Interaction statistics',
                    style: TextStyle(color: ext.muted, fontSize: 12)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/admin/dashboard/ai-logs'),
                child: Text('View all logs →',
                    style: TextStyle(color: AdminColors.neonGreen,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 16),

            if (_aiLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AdminColors.neonGreen, strokeWidth: 2)))
            else
              _AiQuickStats(
                total:        aiOv['total']          as int? ?? 0,
                successRate:  aiOv['successRate']     as int? ?? 0,
                playerTotal:  aiOv['playerTotal']     as int? ?? 0,
                managerTotal: aiOv['managerTotal']    as int? ?? 0,
                avgMs:        (aiPerf['avgProcessingMs'] as num?)?.toDouble() ?? 0,
                convRate:     aiConv['bookingConversionPct'] as int? ?? 0,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── AI quick stats strip ─────────────────────────────────────────────────────

class _AiQuickStats extends StatelessWidget {
  const _AiQuickStats({
    required this.total, required this.successRate,
    required this.playerTotal, required this.managerTotal,
    required this.avgMs, required this.convRate,
  });
  final int    total, successRate, playerTotal, managerTotal, convRate;
  final double avgMs;

  static String _ms(double v) =>
      v < 1000 ? '${v.round()} ms' : '${(v / 1000).toStringAsFixed(1)} s';

  @override
  Widget build(BuildContext context) {
    final ext  = context.adminExt;
    final w    = MediaQuery.of(context).size.width;
    final cols = w > 1000 ? 3 : 2;

    final items = [
      _AiTile(value: '$total',        label: 'Total interactions',  color: AdminColors.indigo),
      _AiTile(value: '$successRate%', label: 'Success rate',        color: AdminColors.neonGreen),
      _AiTile(value: '$playerTotal',  label: 'Player sessions',     color: AdminColors.sky),
      _AiTile(value: '$managerTotal', label: 'Manager sessions',    color: AdminColors.violet),
      _AiTile(value: _ms(avgMs),      label: 'Avg response time',   color: AdminColors.amber),
      _AiTile(value: '$convRate%',    label: 'Booking conversion',  color: AdminColors.emerald),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        ext.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: ext.border),
      ),
      child: GridView.count(
        crossAxisCount:   cols,
        crossAxisSpacing: 0,
        mainAxisSpacing:  0,
        childAspectRatio: 3.5,
        shrinkWrap:       true,
        physics:          const NeverScrollableScrollPhysics(),
        children: items,
      ),
    );
  }
}

class _AiTile extends StatelessWidget {
  const _AiTile({required this.value, required this.label, required this.color});
  final String value, label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: GoogleFonts.montserrat(
                  color: ext.text, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(color: ext.muted, fontSize: 11)),
        ]),
      ]),
    );
  }
}
