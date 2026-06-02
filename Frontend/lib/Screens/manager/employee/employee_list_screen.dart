import 'package:Arena/models/models.dart';
import 'package:Arena/Screens/manager/employee/add_employee_screen.dart';
import 'package:Arena/Screens/manager/employee/employee_detail_screen.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ManagerEmployeesScreen extends StatefulWidget {
  const ManagerEmployeesScreen({super.key});

  @override
  State<ManagerEmployeesScreen> createState() => _ManagerEmployeesScreenState();
}

class _ManagerEmployeesScreenState extends State<ManagerEmployeesScreen> {
  List<Employee> _all      = [];
  List<Employee> _filtered = [];
  bool   _loading = true;
  String? _error;
  final  _searchCtrl = TextEditingController();

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
    setState(() { _loading = true; _error = null; });
    try {
      final list = await context.read<EmployeeService>().getManagerEmployees();
      if (mounted) setState(() { _all = list; _filtered = list; _loading = false; });
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Parse error: $e'; _loading = false; });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((e) =>
              e.username.toLowerCase().contains(q) ||
              e.email.toLowerCase().contains(q)).toList();
    });
  }

  void _openAdd() async {
    final terrainProv = context.read<TerrainProvider>();
    final terrainSvc  = context.read<TerrainService>();
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
    );
    if (added == true && mounted) {
      _fetch();
      // Employee may have been assigned to a terrain — keep TerrainProvider in sync.
      terrainProv.refresh(terrainSvc);
    }
  }

  void _openDetail(Employee emp) async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employee: emp)),
    );
    if (result != null) _fetch(); // 'updated' or 'deleted'
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
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Employees',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  Material(
                    color: AppColors.neonGreen,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _openAdd,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.userPlus,
                                color: Colors.black, size: 12),
                            const SizedBox(width: 6),
                            Text('Register',
                                style: GoogleFonts.montserrat(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search ────────────────────────────────────────────────────
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
                    const FaIcon(FontAwesomeIcons.magnifyingGlass,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search employees...',
                          hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14),
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

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.neonGreen))
                  : _error != null
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _fetch,
                              child: Text('Retry',
                                  style: GoogleFonts.inter(
                                      color: AppColors.neonGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]))
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const FaIcon(FontAwesomeIcons.userSlash,
                                    color: AppColors.textSecondary, size: 40),
                                const SizedBox(height: 14),
                                Text('No employees found.',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 14)),
                              ]))
                          : RefreshIndicator(
                              color: AppColors.neonGreen,
                              onRefresh: _fetch,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (_, i) => _EmployeeCard(
                                  employee: _filtered[i],
                                  onTap: () => _openDetail(_filtered[i]),
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

// ─── Employee card ────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.onTap});
  final Employee employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAssigned = employee.terrain != null;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color.fromRGBO(46, 204, 113, 0.12),
                child: Text(
                  employee.username.isNotEmpty
                      ? employee.username[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.montserrat(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.username,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(employee.email,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FaIcon(
                          isAssigned
                              ? FontAwesomeIcons.trophy
                              : FontAwesomeIcons.circleXmark,
                          color: isAssigned
                              ? AppColors.neonGreen
                              : AppColors.textSecondary,
                          size: 11,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAssigned
                              ? 'Terrain #${employee.terrain}'
                              : 'Unassigned',
                          style: GoogleFonts.inter(
                              color: isAssigned
                                  ? AppColors.neonGreen
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const FaIcon(FontAwesomeIcons.chevronRight,
                  color: AppColors.textSecondary, size: 11),
            ],
          ),
        ),
      ),
    );
  }
}
