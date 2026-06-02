import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/widgets/admin_data_table.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:flutter/material.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r    = await AdminClient.get('/admin/employees');
      final data = r.data;
      final list = data is List ? data : (data['result'] as List? ?? []);
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
            title:    'Employees',
            subtitle: 'Terrain staff assigned by campus managers',
            badge:    'Read-only',
          ),
          const SizedBox(height: 20),
          AdminDataTable(
            columns: const [
              AdminColumn('id',       'ID',       mono: true),
              AdminColumn('username', 'Username', flex: 2),
              AdminColumn('email',    'Email',    flex: 3),
              AdminColumn('phone',    'Phone',    flex: 2),
              AdminColumn('address',  'Address',  flex: 2),
              AdminColumn('terrain',  'Terrain'),
            ],
            rows:         _rows,
            loading:      _loading,
            error:        _error,
            emptyLabel:   'No employees found.',
            searchFields: const ['username', 'email', 'phone', 'address'],
            cellBuilder: (key, value, row) {
              if (key == 'terrain') {
                final t = row['terrain'];
                if (t == null) {
                  return Text('Unassigned',
                      style: TextStyle(
                          color:    Colors.grey.shade500, fontSize: 12));
                }
                final id = t is Map ? t['id'] : t;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        AdminColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AdminColors.teal.withValues(alpha: 0.35)),
                  ),
                  child: Text('#$id',
                      style: const TextStyle(
                          color:      AdminColors.teal,
                          fontSize:   11,
                          fontWeight: FontWeight.w600)),
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
