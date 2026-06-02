import 'package:Arena/models/User/user.dart';
import 'package:Arena/models/summaries.dart';

class Player {
  final int id;
  final String? nom;
  final String? address;
  final String? phone;
  final String? firebaseUid;
  final String? fcmToken;
  final AuthUser? user;
  final List<ReservationSummary> reservations;

  const Player({
    required this.id,
    this.nom,
    this.address,
    this.phone,
    this.firebaseUid,
    this.fcmToken,
    this.user,
    this.reservations = const [],
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as int,
        nom: json['nom'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        firebaseUid: json['firebaseUid'] as String?,
        fcmToken: json['fcmToken'] as String?,
        user: json['user'] != null
            ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        reservations: (json['reservations'] as List<dynamic>? ?? [])
            .map((e) => ReservationSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UpdatePlayerRequest {
  final String? username;
  final String? email;
  final String? address;
  final String? phone;

  const UpdatePlayerRequest({this.username, this.email, this.address, this.phone});

  Map<String, dynamic> toJson() => {
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
      };
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? address;
  final String? phone;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.address,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
      };
}
