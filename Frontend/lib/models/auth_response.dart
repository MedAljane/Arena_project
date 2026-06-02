import 'package:Arena/models/User/user.dart';

class AuthResponse {
  final AuthUser user;
  final String token;

  const AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
      );
}
