import 'package:Arena/admin/providers/admin_auth_provider.dart';
import 'package:Arena/admin/screens/login/admin_login_screen.dart';
import 'package:Arena/admin/screens/shell/admin_shell.dart';
import 'package:Arena/admin/screens/overview/overview_screen.dart';
import 'package:Arena/admin/screens/admins/admins_screen.dart';
import 'package:Arena/admin/screens/managers/managers_screen.dart';
import 'package:Arena/admin/screens/players/players_screen.dart';
import 'package:Arena/admin/screens/campuses/campuses_screen.dart';
import 'package:Arena/admin/screens/employees/employees_screen.dart';
import 'package:Arena/admin/screens/terrains/terrains_screen.dart';
import 'package:Arena/admin/screens/week_agendas/week_agendas_screen.dart';
import 'package:Arena/admin/screens/manager/manager_shell.dart';
import 'package:Arena/admin/screens/manager/overview/manager_overview_screen.dart';
import 'package:Arena/admin/screens/manager/campus/manager_campus_screen.dart';
import 'package:Arena/admin/screens/manager/employees/manager_employees_screen.dart';
import 'package:Arena/admin/screens/manager/agendas/manager_agendas_screen.dart';
import 'package:Arena/admin/screens/manager/agendas/manager_agenda_detail_screen.dart';
import 'package:Arena/admin/screens/manager/reservations/manager_reservations_screen.dart';
import 'package:Arena/admin/screens/manager/profile/manager_profile_screen.dart';
import 'package:go_router/go_router.dart';

GoRouter buildAdminRouter(AdminAuthProvider auth) => GoRouter(
  refreshListenable: auth,
  initialLocation:   '/login',
  redirect: (context, state) {
    final loggedIn = auth.isLoggedIn;
    final loc      = state.matchedLocation;
    final isLogin  = loc == '/login';
    final role     = auth.userRole;           // declared once, used everywhere below

    if (!loggedIn && !isLogin) return '/login';

    if (loggedIn && isLogin) {
      if (role == 'admin')   return '/admin/dashboard/overview';
      if (role == 'manager') return '/manager/dashboard';
      return null; // unknown role: stay on login, don't loop
    }

    // Role-based protection — only when role is known to prevent cross-redirect loops
    if (role != null) {
      if (loc.startsWith('/admin')   && role != 'admin')   return '/manager/dashboard';
      if (loc.startsWith('/manager') && role != 'manager') return '/admin/dashboard/overview';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const AdminLoginScreen()),

    // ── Admin routes ──────────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin/dashboard', redirect: (_, __) => '/admin/dashboard/overview'),
        GoRoute(path: '/admin/dashboard/overview',    builder: (_, __) => const OverviewScreen()),
        GoRoute(path: '/admin/dashboard/admins',      builder: (_, __) => const AdminsScreen()),
        GoRoute(path: '/admin/dashboard/managers',    builder: (_, __) => const ManagersScreen()),
        GoRoute(path: '/admin/dashboard/players',     builder: (_, __) => const PlayersScreen()),
        GoRoute(path: '/admin/dashboard/campuses',    builder: (_, __) => const CampusesScreen()),
        GoRoute(path: '/admin/dashboard/employees',   builder: (_, __) => const EmployeesScreen()),
        GoRoute(path: '/admin/dashboard/terrains',    builder: (_, __) => const TerrainsScreen()),
        GoRoute(path: '/admin/dashboard/week-agendas',builder: (_, __) => const WeekAgendasScreen()),
      ],
    ),

    // ── Manager routes ────────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => ManagerWebShell(child: child),
      routes: [
        GoRoute(path: '/manager/dashboard', builder: (_, __) => const ManagerOverviewScreen()),
        GoRoute(path: '/manager/campus',    builder: (_, __) => const ManagerCampusScreen()),
        GoRoute(path: '/manager/employees', builder: (_, __) => const ManagerEmployeesWebScreen()),
        GoRoute(path: '/manager/agendas',   builder: (_, __) => const ManagerAgendasScreen()),
        GoRoute(
          path:    '/manager/agendas/:id',
          builder: (_, state) => ManagerAgendaDetailScreen(
            agendaId:      int.parse(state.pathParameters['id']!),
            agendaTitle:   state.uri.queryParameters['title'] ?? 'Agenda',
          ),
        ),
        GoRoute(path: '/manager/reservations', builder: (_, __) => const ManagerReservationsScreen()),
        GoRoute(path: '/manager/profile',      builder: (_, __) => const ManagerProfileWebScreen()),
      ],
    ),
  ],
);
