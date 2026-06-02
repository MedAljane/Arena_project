import 'package:Arena/models/enums.dart';

class AuthUser {
  final int id;
  final String username;
  final String email;
  final UserRole userRole;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.userRole,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        userRole: UserRole.values.byName(json['user_role'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'user_role': userRole.name,
      };
}
