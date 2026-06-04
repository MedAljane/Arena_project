import 'package:Arena/admin/api/admin_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthProvider extends ChangeNotifier {
  static const _tokenKey = 'admin_token';
  static const _emailKey = 'admin_email';
  static const _roleKey  = 'admin_role';

  String? _token;
  String? _email;
  String? _role;

  String? get token      => _token;
  String? get email      => _email;
  String? get userRole   => _role;
  bool    get isLoggedIn => _token != null;
  bool    get isAdmin    => _role == 'admin';
  bool    get isManager  => _role == 'manager';

  Future<void> tryRestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(_tokenKey);
      final e = prefs.getString(_emailKey);
      final r = prefs.getString(_roleKey);

      if (t != null && (r == 'admin' || r == 'manager')) {
        _token = t;
        _email = e;
        _role  = r;
        AdminClient.setToken(t);
        notifyListeners();
      } else if (t != null) {
        // Stale session (no role stored) — clear it so the router doesn't loop.
        await prefs.remove(_tokenKey);
        await prefs.remove(_emailKey);
        await prefs.remove(_roleKey);
      }
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    final response = await AdminClient.post('/auth/login', {
      'email':    email,
      'password': password,
    });
    final data  = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    final user  = data['user']  as Map<String, dynamic>?;

    if (token == null) throw Exception('No token returned');

    final role = user?['user_role'] as String?;
    if (role != 'admin' && role != 'manager') {
      throw Exception('Access denied. Admin or Manager accounts only.');
    }

    _token = token;
    _email = user?['email'] as String? ?? email;
    _role  = role;
    AdminClient.setToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, _email!);
    await prefs.setString(_roleKey,  _role!);

    notifyListeners();
  }

  Future<void> logout() async {
    try { await AdminClient.post('/auth/logout', null); } catch (_) {}
    _token = null;
    _email = null;
    _role  = null;
    AdminClient.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);

    notifyListeners();
  }
}
