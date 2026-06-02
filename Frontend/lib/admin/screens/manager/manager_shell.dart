import 'package:Arena/admin/providers/admin_auth_provider.dart';
import 'package:Arena/admin/providers/admin_theme_provider.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ManagerWebShell extends StatelessWidget {
  const ManagerWebShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adminExt.bg,
      body: Row(
        children: [
          const _ManagerSidebar(),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ManagerSidebar extends StatelessWidget {
  const _ManagerSidebar();

  static const _nav = [
    _NavItem('/manager/dashboard',    'Dashboard',    Icons.grid_view_rounded),
    _NavItem('/manager/campus',       'Campus',       Icons.location_city_outlined),
    _NavItem('/manager/employees',    'Employees',    Icons.badge_outlined),
    _NavItem('/manager/agendas',      'Agendas',      Icons.calendar_today_outlined),
    _NavItem('/manager/reservations', 'Reservations', Icons.pending_actions_outlined),
    _NavItem('/manager/profile',      'Profile',      Icons.manage_accounts_outlined),
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
                  child: const Icon(Icons.sports, color: Colors.black, size: 18),
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
                    Text('Manager Portal',
                        style: TextStyle(
                            color: ext.muted, fontSize: 10, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: ext.border, height: 1),

          // ── Nav ───────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                children: _nav.map((n) =>
                    _NavTile(item: n, active: loc == n.path ||
                        (n.path != '/manager/dashboard' && loc.startsWith(n.path)))).toList(),
              ),
            ),
          ),

          Divider(color: ext.border, height: 1),

          // ── Bottom ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _BottomBtn(
                  icon:  theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: theme.isDark ? 'Light mode' : 'Dark mode',
                  onTap: () => context.read<AdminThemeProvider>().toggle(),
                  ext:   ext,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AdminColors.neonGreen.withValues(alpha: 0.18),
                        child: Text(
                          (auth.email?.isNotEmpty == true)
                              ? auth.email![0].toUpperCase() : 'M',
                          style: const TextStyle(
                              color: AdminColors.neonGreen,
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(auth.email ?? 'Manager',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ext.muted, fontSize: 12)),
                      ),
                      IconButton(
                        tooltip:     'Sign out',
                        icon:        Icon(Icons.logout, size: 16, color: ext.subtle),
                        padding:     EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed:   () => context.read<AdminAuthProvider>().logout(),
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
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String   path;
  final String   label;
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
          padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color:        active
                ? AdminColors.neonGreen.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 17,
                  color: active ? AdminColors.neonGreen : ext.muted),
              const SizedBox(width: 10),
              Flexible(
                child: Text(item.label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:      active ? AdminColors.neonGreen : ext.muted,
                      fontSize:   13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({required this.icon, required this.label,
      required this.onTap, required this.ext});
  final IconData   icon;
  final String     label;
  final VoidCallback onTap;
  final AdminExt   ext;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            Icon(icon, size: 16, color: ext.muted),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: ext.muted, fontSize: 13)),
          ]),
        ),
      );
}
