import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/widgets/admin_data_table.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:flutter/material.dart';

class CampusesScreen extends StatefulWidget {
  const CampusesScreen({super.key});
  @override
  State<CampusesScreen> createState() => _CampusesScreenState();
}

class _CampusesScreenState extends State<CampusesScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r    = await AdminClient.get('/admin/get-all-campuses');
      final data = r.data;
      final list = data is List ? data : (data['data'] as List? ?? []);
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
            title:    'Campuses',
            subtitle: 'All campuses — managed by their respective managers',
            badge:    'Read-only',
          ),
          const SizedBox(height: 20),
          AdminDataTable(
            columns: const [
              AdminColumn('id',      'ID',      mono: true),
              AdminColumn('Name',    'Name',    flex: 2),
              AdminColumn('Address', 'Address', flex: 3),
              AdminColumn('manager', 'Manager', flex: 2),
              AdminColumn('status',  'Status'),
            ],
            rows:         _rows,
            loading:      _loading,
            error:        _error,
            emptyLabel:   'No campuses found.',
            searchFields: const ['Name', 'Address'],
            cellBuilder: (key, value, row) {
              if (key == 'manager') {
                final m = row['manager'] as Map?;
                return Text(
                  m?['email'] ?? m?['username'] ?? '—',
                  style: const TextStyle(fontSize: 13),
                );
              }
              if (key == 'status') {
                final published = row['publishedAt'] != null;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: published
                        ? AdminColors.emerald.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: published
                          ? AdminColors.emerald.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    published ? 'Published' : 'Draft',
                    style: TextStyle(
                      color:      published ? AdminColors.emerald : Colors.grey,
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                    ),
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
