import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:dio/dio.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  /// POST /auth/login — returns user + JWT, sets the token on ApiService.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      final result = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      _api.setToken(result.token);
      return result;
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// POST /auth/register — creates a player account, sets the token on ApiService.
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _api.post('/auth/register', request.toJson());
      final result = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      _api.setToken(result.token);
      return result;
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// GET /auth/me — returns the current authenticated user.
  Future<AuthUser> getMe() async {
    try {
      final response = await _api.get('/auth/me');
      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// POST /auth/logout — blacklists the token server-side, then clears it locally.
  /// The token is always cleared even if the server call fails.
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', null);
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    } finally {
      _api.clearToken();
    }
  }

  /// POST /auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.post('/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// POST /auth/forgot-password — triggers a password-reset email.
  Future<void> forgotPassword(String email) async {
    try {
      await _api.post('/auth/forgot-password', {'email': email});
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// POST /auth/reset-password — consumes the emailed token and sets a new password.
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _api.post('/auth/reset-password', {
        'token': token,
        'password': password,
      });
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  // Extracts a human-readable message from a DioException response body.
  // Handles both { "error": { "message": "..." } } and plain-string 400 bodies.
  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiError.fromJson(data).message;
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return e.message ?? 'An unexpected error occurred';
  }
}
