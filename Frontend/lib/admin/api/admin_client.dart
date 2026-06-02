import 'package:Arena/core/config.dart';
import 'package:dio/dio.dart';

/// Isolated Dio client for the web admin dashboard.
/// Completely independent from the mobile app's ApiService.
class AdminClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl:        kApiBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers:        {'Content-Type': 'application/json'},
    ),
  );

  static void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  static Future<Response> get(String path)    => _dio.get(path);
  static Future<Response> post(String path, dynamic data) =>
      _dio.post(path, data: data);
  static Future<Response> put(String path, dynamic data) =>
      _dio.put(path, data: data);
  static Future<Response> delete(String path) => _dio.delete(path);

  /// Extracts a human-readable message from a DioException response body
  /// so screens show "Email already in use" instead of the full Dio stack.
  static String errorMessage(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        // { "error": { "message": "..." } }  — Strapi v4/v5 format
        final msg = data['error']?['message']
            ?? data['message']
            ?? data['error']?.toString();
        if (msg != null && msg.toString().isNotEmpty) return msg.toString();
      }
      if (data is String && data.isNotEmpty) return data;
      if (e.response?.statusCode != null) {
        return 'Server error ${e.response!.statusCode}';
      }
      return e.message ?? 'Request failed';
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
