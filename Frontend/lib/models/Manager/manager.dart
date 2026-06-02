import 'package:Arena/models/User/user.dart';
import 'package:Arena/models/summaries.dart';

class Manager {
  final int id;
  final String? nom;
  final String? address;
  final String? phone;
  final String? firebaseUid;
  final String? fcmToken;
  final AuthUser? user;
  final List<CampusSummary> campuses;
  final List<EmployeeSummary> employees;

  const Manager({
    required this.id,
    this.nom,
    this.address,
    this.phone,
    this.firebaseUid,
    this.fcmToken,
    this.user,
    this.campuses = const [],
    this.employees = const [],
  });

  factory Manager.fromJson(Map<String, dynamic> json) => Manager(
        id: json['id'] as int,
        nom: json['nom'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        firebaseUid: json['firebaseUid'] as String?,
        fcmToken: json['fcmToken'] as String?,
        user: json['user'] != null
            ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        campuses: (json['campuses'] as List<dynamic>? ?? [])
            .map((e) => CampusSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        employees: (json['employees'] as List<dynamic>? ?? [])
            .map((e) => EmployeeSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UpdateManagerRequest {
  final String? username;
  final String? email;
  final String? address;
  final String? phone;

  const UpdateManagerRequest({this.username, this.email, this.address, this.phone});

  Map<String, dynamic> toJson() => {
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
      };
}
