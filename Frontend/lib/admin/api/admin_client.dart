import 'package:Arena/core/config.dart';
import 'package:dio/dio.dart';

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

  static String errorMessage(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
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
