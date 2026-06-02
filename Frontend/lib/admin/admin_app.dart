import 'package:Arena/admin/providers/admin_auth_provider.dart';
import 'package:Arena/admin/providers/admin_theme_provider.dart';
import 'package:Arena/admin/router/admin_router.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final AdminAuthProvider  _auth;
  late final AdminThemeProvider _theme;

  @override
  void initState() {
    super.initState();
    _auth  = AdminAuthProvider();
    _theme = AdminThemeProvider();
    _auth.tryRestore();
    _theme.load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _theme),
      ],
      child: _AdminMaterialApp(auth: _auth, theme: _theme),
    );
  }
}

class _AdminMaterialApp extends StatefulWidget {
  const _AdminMaterialApp({required this.auth, required this.theme});
  final AdminAuthProvider  auth;
  final AdminThemeProvider theme;

  @override
  State<_AdminMaterialApp> createState() => _AdminMaterialAppState();
}

class _AdminMaterialAppState extends State<_AdminMaterialApp> {
  late final router = buildAdminRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.watch<AdminThemeProvider>().themeMode;

    return MaterialApp.router(
      title:            'Arena Admin',
      debugShowCheckedModeBanner: false,
      theme:            AdminTheme.light(),
      darkTheme:        AdminTheme.dark(),
      themeMode:        themeMode,
      routerConfig:     router,
    );
  }
}
