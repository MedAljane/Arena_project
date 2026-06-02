import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _loading = true;
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminClient.get('/admin/admins'),
        AdminClient.get('/admin/managers'),
        AdminClient.get('/admin/players'),
        AdminClient.get('/admin/get-all-campuses'),
        AdminClient.get('/admin/employees'),
        AdminClient.get('/admin/terrains'),
        AdminClient.get('/admin/week-agendas'),
      ]);

      int len(dynamic data, [String? key]) {
        if (data == null) return 0;
        if (data is List) return data.length;
        final map = data as Map<String, dynamic>;
        if (key != null && map[key] is List) return (map[key] as List).length;
        for (final v in map.values) {
          if (v is List) return v.length;
        }
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
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext  = context.adminExt;
    final w    = MediaQuery.of(context).size.width;
    final cols = w > 1200 ? 4 : (w > 800 ? 3 : 2);

    return RefreshIndicator(
      color:    AdminColors.neonGreen,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Text('Overview',
                style: TextStyle(
                    color:      ext.text,
                    fontSize:   24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Platform summary at a glance',
                style: TextStyle(color: ext.muted, fontSize: 14)),
            const SizedBox(height: 28),

            // ── Stat grid ────────────────────────────────────────────────────
            GridView.count(
              crossAxisCount:       cols,
              crossAxisSpacing:     16,
              mainAxisSpacing:      16,
              childAspectRatio:     1.7,
              shrinkWrap:           true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(label: 'Admins',       value: '${_counts['admins']  ?? 0}', icon: Icons.shield_outlined,          color: AdminColors.indigo,   route: '/dashboard/admins',       loading: _loading),
                StatCard(label: 'Managers',     value: '${_counts['managers']?? 0}', icon: Icons.manage_accounts_outlined,  color: AdminColors.violet,   route: '/dashboard/managers',     loading: _loading),
                StatCard(label: 'Players',      value: '${_counts['players'] ?? 0}', icon: Icons.person_outline,            color: AdminColors.sky,      route: '/dashboard/players',      loading: _loading),
                StatCard(label: 'Campuses',     value: '${_counts['campuses']?? 0}', icon: Icons.location_city_outlined,    color: AdminColors.emerald,  route: '/dashboard/campuses',     loading: _loading),
                StatCard(label: 'Employees',    value: '${_counts['employees']??0}', icon: Icons.badge_outlined,            color: AdminColors.amber,    route: '/dashboard/employees',    loading: _loading),
                StatCard(label: 'Terrains',     value: '${_counts['terrains']?? 0}', icon: Icons.sports_soccer_outlined,    color: AdminColors.teal,     route: '/dashboard/terrains',     loading: _loading),
                StatCard(label: 'Week Agendas', value: '${_counts['agendas'] ?? 0}', icon: Icons.calendar_today_outlined,   color: AdminColors.rose,     route: '/dashboard/week-agendas', loading: _loading),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
