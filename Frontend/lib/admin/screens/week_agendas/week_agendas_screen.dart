import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/widgets/admin_data_table.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:flutter/material.dart';

class WeekAgendasScreen extends StatefulWidget {
  const WeekAgendasScreen({super.key});
  @override
  State<WeekAgendasScreen> createState() => _WeekAgendasScreenState();
}

class _WeekAgendasScreenState extends State<WeekAgendasScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r    = await AdminClient.get('/admin/week-agendas');
      final data = r.data;
      final list = data is List
          ? data
          : (data['agendas'] ?? data['data'] ?? []) as List;
      if (mounted) {
        setState(() {
          _rows    = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title:    'Week Agendas',
            subtitle: 'Published and draft weekly schedules',
            badge:    'Read-only',
          ),
          const SizedBox(height: 20),
          AdminDataTable(
            columns: const [
              AdminColumn('id',            'ID',         mono: true),
              AdminColumn('weekStartDate', 'Week Start', flex: 2),
              AdminColumn('campus',        'Campus',     flex: 2),
              AdminColumn('terrain',       'Terrain'),
              AdminColumn('dayPlans',      'Day Plans'),
              AdminColumn('statu',         'Status'),
            ],
            rows:         _rows,
            loading:      _loading,
            error:        _error,
            emptyLabel:   'No week agendas found.',
            searchFields: const ['weekStartDate'],
            cellBuilder: (key, value, row) {
              if (key == 'campus') {
                final c = row['campus'] as Map?;
                return Text(c?['Name']?.toString() ?? '—',
                    style: const TextStyle(fontSize: 13));
              }
              if (key == 'terrain') {
                final t = row['terrain'] as Map?;
                final type = t?['Type']?.toString() ?? '—';
                return Text(type,
                    style: const TextStyle(fontSize: 13));
              }
              if (key == 'dayPlans') {
                final plans = row['day_plans'] as List?;
                final count = plans?.length ?? 0;
                return Text('$count / 7',
                    style: const TextStyle(fontSize: 13));
              }
              if (key == 'statu') {
                final published = value?.toString() == 'Published';
                final color = published
                    ? AdminColors.neonGreen
                    : AdminColors.warning;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    published ? 'Published' : 'Draft',
                    style: TextStyle(
                        color:      color,
                        fontSize:   11,
                        fontWeight: FontWeight.w600),
                  ),
                );
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
