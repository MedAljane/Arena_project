import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class ManagerOverviewScreen extends StatefulWidget {
  const ManagerOverviewScreen({super.key});

  @override
  State<ManagerOverviewScreen> createState() => _ManagerOverviewScreenState();
}

class _ManagerOverviewScreenState extends State<ManagerOverviewScreen> {
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
        AdminClient.get('/manager/get-campuses'),
        AdminClient.get('/manager/get-terrains'),
        AdminClient.get('/manager/employees'),
        AdminClient.get('/manager/reservations/pending'),
      ]);

      int len(dynamic data, [String? key]) {
        if (data == null) return 0;
        if (data is List) return data.length;
        final map = data as Map<String, dynamic>;
        if (key != null && map[key] is List) { return (map[key] as List).length; }
        for (final v in map.values) { if (v is List) return v.length; }
        return 0;
      }

      if (mounted) setState(() {
        _counts['campuses']     = len(results[0].data);
        _counts['terrains']     = len(results[1].data, 'terrains');
        _counts['employees']    = len(results[2].data, 'result');
        _counts['pending']      = len(results[3].data, 'data');
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext  = context.adminExt;
    final w    = MediaQuery.of(context).size.width;
    final cols = w > 1100 ? 4 : (w > 700 ? 2 : 2);

    return RefreshIndicator(
      color:     AdminColors.neonGreen,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard',
                style: TextStyle(
                    color: ext.text, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Your campus at a glance',
                style: TextStyle(color: ext.muted, fontSize: 14)),
            const SizedBox(height: 28),

            GridView.count(
              crossAxisCount:   cols,
              crossAxisSpacing: 16,
              mainAxisSpacing:  16,
              childAspectRatio: 1.7,
              shrinkWrap:       true,
              physics:          const NeverScrollableScrollPhysics(),
              children: [
                StatCard(label: 'My Campuses',   value: '${_counts['campuses']  ?? 0}', icon: Icons.location_city_outlined,   color: AdminColors.indigo,   route: '/manager/campus',       loading: _loading),
                StatCard(label: 'Terrains',       value: '${_counts['terrains']  ?? 0}', icon: Icons.sports_soccer_outlined,   color: AdminColors.emerald,  route: '/manager/campus',       loading: _loading),
                StatCard(label: 'Employees',      value: '${_counts['employees'] ?? 0}', icon: Icons.badge_outlined,           color: AdminColors.sky,      route: '/manager/employees',    loading: _loading),
                StatCard(label: 'Pending Reservations', value: '${_counts['pending'] ?? 0}', icon: Icons.pending_actions_outlined, color: _counts['pending'] != null && _counts['pending']! > 0 ? AdminColors.warning : AdminColors.teal, route: '/manager/reservations', loading: _loading),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
