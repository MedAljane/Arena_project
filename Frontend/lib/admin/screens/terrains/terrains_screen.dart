import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/widgets/admin_data_table.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:flutter/material.dart';

class TerrainsScreen extends StatefulWidget {
  const TerrainsScreen({super.key});
  @override
  State<TerrainsScreen> createState() => _TerrainsScreenState();
}

class _TerrainsScreenState extends State<TerrainsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool    _loading = true;
  String? _error;

  static const _typeColors = {
    'Football':   AdminColors.emerald,
    'Basketball': AdminColors.amber,
    'Padel':      AdminColors.sky,
    'Tennis':     AdminColors.violet,
    'Paddel':     AdminColors.sky,
  };

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r    = await AdminClient.get('/admin/terrains');
      final data = r.data;
      final list = data is List
          ? data
          : (data['terrains'] ?? data['result'] ?? data['data'] ?? []) as List;
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
            title:    'Terrains',
            subtitle: 'All terrains across all campuses',
            badge:    'Read-only',
          ),
          const SizedBox(height: 20),
          AdminDataTable(
            columns: const [
              AdminColumn('id',       'ID',       mono: true),
              AdminColumn('Type',     'Type'),
              AdminColumn('campus',   'Campus',   flex: 3),
              AdminColumn('employee', 'Employee', flex: 2),
            ],
            rows:         _rows,
            loading:      _loading,
            error:        _error,
            emptyLabel:   'No terrains found.',
            searchFields: const ['Type'],
            cellBuilder: (key, value, row) {
              if (key == 'Type') {
                final t   = value?.toString() ?? '';
                final col = _typeColors[t] ?? Colors.grey;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color:        col.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: col.withValues(alpha: 0.4)),
                  ),
                  child: Text(t.isEmpty ? '—' : t,
                      style: TextStyle(
                          color:      col,
                          fontSize:   11,
                          fontWeight: FontWeight.w600)),
                );
              }
              if (key == 'campus') {
                final c = row['campus'] as Map?;
                if (c == null) return null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c['Name']?.toString() ?? '—',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    if (c['Address'] != null)
                      Text(c['Address'].toString(),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11)),
                  ],
                );
              }
              if (key == 'employee') {
                final emp = row['employee'] as Map?;
                if (emp == null) {
                  return Text('Unassigned',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12));
                }
                return Text(
                  emp['username']?.toString() ??
                      emp['email']?.toString() ??
                      '#${emp['id']}',
                  style: const TextStyle(fontSize: 13),
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
