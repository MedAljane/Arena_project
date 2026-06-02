import 'package:Arena/admin/providers/admin_auth_provider.dart';
import 'package:Arena/admin/providers/admin_theme_provider.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adminExt.bg,
      body: Row(
        children: [
          const _Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  static const _managementNav = [
    _NavItem('/admin/dashboard/overview',     'Overview',     Icons.grid_view_rounded),
    _NavItem('/admin/dashboard/admins',       'Admins',       Icons.shield_outlined),
    _NavItem('/admin/dashboard/managers',     'Managers',     Icons.manage_accounts_outlined),
    _NavItem('/admin/dashboard/players',      'Players',      Icons.person_outline),
  ];

  static const _operationsNav = [
    _NavItem('/admin/dashboard/campuses',     'Campuses',     Icons.location_city_outlined),
    _NavItem('/admin/dashboard/employees',    'Employees',    Icons.badge_outlined),
    _NavItem('/admin/dashboard/terrains',     'Terrains',     Icons.sports_soccer_outlined),
    _NavItem('/admin/dashboard/week-agendas', 'Week Agendas', Icons.calendar_today_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final ext   = context.adminExt;
    final auth  = context.watch<AdminAuthProvider>();
    final theme = context.watch<AdminThemeProvider>();
    final loc   = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 220,
      color: ext.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color:        AdminColors.neonGreen,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.sports,
                      color: Colors.black, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arena',
                        style: TextStyle(
                            color:      ext.text,
                            fontSize:   15,
                            fontWeight: FontWeight.w800)),
                    Text('Admin Panel',
                        style: TextStyle(
                            color:    ext.muted,
                            fontSize: 10,
                            letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: ext.border, height: 1),

          // ── Navigation ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Management', ext),
                  const SizedBox(height: 4),
                  ..._managementNav.map((n) => _NavTile(item: n, active: loc == n.path)),
                  const SizedBox(height: 20),
                  _sectionLabel('Operations', ext),
                  const SizedBox(height: 4),
                  ..._operationsNav.map((n) => _NavTile(item: n, active: loc == n.path)),
                ],
              ),
            ),
          ),

          Divider(color: ext.border, height: 1),

          // ── Bottom actions ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Theme toggle
                _BottomAction(
                  icon:  theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: theme.isDark ? 'Light mode' : 'Dark mode',
                  ext:   ext,
                  onTap: () => context.read<AdminThemeProvider>().toggle(),
                ),
                const SizedBox(height: 4),
                // User row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AdminColors.indigo
                            .withValues(alpha: 0.2),
                        child: Text(
                          (auth.email?.isNotEmpty == true)
                              ? auth.email![0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                              color:      AdminColors.indigo,
                              fontSize:   12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.email ?? 'Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: ext.muted, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        tooltip:     'Sign out',
                        icon:        Icon(Icons.logout,
                            size: 16, color: ext.subtle),
                        padding:     EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                        onPressed: () async {
                          await context
                              .read<AdminAuthProvider>()
                              .logout();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, AdminExt ext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              color:       ext.subtle,
              fontSize:    10,
              fontWeight:  FontWeight.w700,
              letterSpacing: 1.2),
        ),
      );
}

// ─── Nav tile ─────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String  path;
  final String  label;
  final IconData icon;
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active});
  final _NavItem item;
  final bool     active;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap:        () => context.go(item.path),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:     const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AdminColors.neonGreen.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size:  17,
                color: active ? AdminColors.neonGreen : ext.muted,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:      active ? AdminColors.neonGreen : ext.muted,
                    fontSize:   13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.ext,
    required this.onTap,
  });
  final IconData   icon;
  final String     label;
  final AdminExt   ext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: ext.muted),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(color: ext.muted, fontSize: 13)),
            ],
          ),
        ),
      );
}
