// ignore_for_file: avoid_print
import 'dart:io';
import 'package:Arena/core/config.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiService {
  late final Dio dio;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Allow self-signed certificates on the local dev server.
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
        HttpClient()..badCertificateCallback = (cert, host, port) => true;

    // Logs every request, response, and error to the run console.
    dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[API] $obj'),
    ));
  }

  String _getBaseUrl() => kApiBase;

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }

  Future<Response> get(String url) => dio.get(url);
  Future<Response> post(String url, dynamic data) => dio.post(url, data: data);
  Future<Response> put(String url, dynamic data) => dio.put(url, data: data);
  Future<Response> delete(String url) => dio.delete(url);
  Future<Response> postMultipart(String url, FormData formData) =>
      dio.post(url, data: formData,
          options: Options(contentType: 'multipart/form-data'));
}
