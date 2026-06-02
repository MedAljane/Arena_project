import 'package:Arena/models/api_error.dart';
import 'package:dio/dio.dart';

class ServiceException implements Exception {
  final String message;
  const ServiceException(this.message);

  @override
  String toString() => message;
}

/// Pulls a human-readable error message out of a Dio error response.
/// Handles { "error": { "message": "..." } } and plain-string 400 bodies.
String extractErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    return ApiError.fromJson(data).message;
  }
  if (data is String && data.isNotEmpty) return data;
  return e.message ?? 'An unexpected error occurred';
}
