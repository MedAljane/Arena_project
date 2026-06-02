import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/core/utils/shared_prefs.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/auth/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Holds the authenticated user's session.
/// All screens should read from this — never from UserProvider (deleted).
class AuthProvider extends ChangeNotifier {
  AuthUser? _user;

  String _displayName = '';
  String _phone = '';
  String _location = '';
  int _notificationCount = 0;

  AuthUser? get authUser => _user;
  bool get isLoggedIn => _user != null;
  UserRole? get role => _user?.userRole;
  String get email => _user?.email ?? '';
  String get phone => _phone;
  String get location => _location;
  int get notificationCount => _notificationCount;

  String get name =>
      _displayName.isNotEmpty ? _displayName : (_user?.username ?? 'User');

  String get avatarInitials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final s = name.trim();
    return s.substring(0, s.length.clamp(1, 2)).toUpperCase();
  }

  /// Persists session to SharedPrefs so it survives app restarts.
  Future<void> setSession(AuthResponse response, ApiService api) async {
    _user = response.user;
    _displayName = response.user.username;
    api.setToken(response.token);
    await SharedPrefs.saveToken(response.token);
    notifyListeners();
  }

  /// Clears session from memory and SharedPrefs.
  Future<void> clearSession(ApiService api) async {
    _user = null;
    _displayName = '';
    _phone = '';
    _location = '';
    api.clearToken();
    await SharedPrefs.clearToken();
    notifyListeners();
  }

  /// Called once at app launch from SplashScreen.
  /// Reads the persisted token, validates it with /auth/me, and restores the
  /// session if valid. Returns the restored user's role, or null if no valid
  /// session exists.
  Future<UserRole?> tryRestoreSession(
      ApiService api, AuthService authService) async {
    final token = await SharedPrefs.getToken();
    if (token == null) return null;
    try {
      api.setToken(token);
      final user = await authService.getMe();
      _user = user;
      _displayName = user.username;
      notifyListeners();
      return user.userRole;
    } catch (_) {
      // Token expired or invalid — wipe it.
      await SharedPrefs.clearToken();
      api.clearToken();
      return null;
    }
  }

  void updateProfile({String? name, String? phone, String? location}) {
    if (name != null) _displayName = name;
    if (phone != null) _phone = phone;
    if (location != null) _location = location;
    notifyListeners();
  }

  void markNotificationsRead() {
    _notificationCount = 0;
    notifyListeners();
  }
}
