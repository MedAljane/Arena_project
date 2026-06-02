class ApiError {
  final String message;

  const ApiError({required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      return ApiError(message: error['message'] as String? ?? 'Unknown error');
    }
    return ApiError(message: json.toString());
  }
}
