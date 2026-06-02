import 'package:Arena/Screens/employee/employee_shell.dart';
import 'package:Arena/Screens/manager/manager_shell.dart';
import 'package:Arena/Screens/player/player_shell.dart';
import 'package:Arena/Screens/shared/splash_screen.dart';
import 'package:Arena/admin/admin_app.dart';
import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/firebase_options.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is only used on mobile (Firestore chat).
  // The web admin dashboard connects to the backend via REST — no Firebase needed.
  if (!kIsWeb) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  runApp(kIsWeb ? const AdminApp() : const ArenaApp());
}

// ─── Mobile app ───────────────────────────────────────────────────────────────

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ProxyProvider<ApiService, AuthService>(
          update: (_, api, _) => AuthService(api),
        ),
        ProxyProvider<ApiService, CampusService>(
          update: (_, api, _) => CampusService(api),
        ),
        ProxyProvider<ApiService, TerrainService>(
          update: (_, api, _) => TerrainService(api),
        ),
        ProxyProvider<ApiService, ReservationService>(
          update: (_, api, _) => ReservationService(api),
        ),
        ProxyProvider<ApiService, WeekAgendaService>(
          update: (_, api, _) => WeekAgendaService(api),
        ),
        ProxyProvider<ApiService, EmployeeService>(
          update: (_, api, _) => EmployeeService(api),
        ),
        ProxyProvider<ApiService, MessageService>(
          update: (_, api, _) => MessageService(api),
        ),
        ProxyProvider<ApiService, AdminService>(
          update: (_, api, _) => AdminService(api),
        ),
        ProxyProvider<ApiService, PlayerService>(
          update: (_, api, _) => PlayerService(api),
        ),
        ProxyProvider<ApiService, ManagerService>(
          update: (_, api, _) => ManagerService(api),
        ),
        ChangeNotifierProvider<PlayerProvider>(create: (_) => PlayerProvider()),
        ChangeNotifierProvider<ManagerProvider>(create: (_) => ManagerProvider()),
        ChangeNotifierProvider<ReservationProvider>(
            create: (_) => ReservationProvider()),
        ChangeNotifierProvider<CampusProvider>(create: (_) => CampusProvider()),
        ChangeNotifierProvider<TerrainProvider>(create: (_) => TerrainProvider()),
        ChangeNotifierProvider<DayPlanProvider>(create: (_) => DayPlanProvider()),
        ChangeNotifierProvider<TimeSlotProvider>(create: (_) => TimeSlotProvider()),
      ],
      child: MaterialApp(
        title: 'Arena',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2ECC71),
            secondary: Color(0xFF2ECC71),
          ),
        ),
        routes: {
          '/player':   (_) => const PlayerShell(),
          '/manager':  (_) => const ManagerShell(),
          '/employee': (_) => const EmployeeShell(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
