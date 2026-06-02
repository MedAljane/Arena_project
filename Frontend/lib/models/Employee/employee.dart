class Employee {
  final int id;
  final String username;
  final String email;
  final String? address;
  final String? phone;
  // Terrain ID the employee is assigned to; null means unassigned.
  final int? terrain;

  const Employee({
    required this.id,
    required this.username,
    required this.email,
    this.address,
    this.phone,
    this.terrain,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        // Backend field is "terrain"; value can be null, int, or a nested object.
        terrain: _parseTerrain(json['terrain']),
      );

  static int? _parseTerrain(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is Map) return (v['id'] as num?)?.toInt();
    return null;
  }
}

class UpdateEmployeeRequest {
  final String? username;
  final String? email;
  final String? address;
  final String? phone;

  const UpdateEmployeeRequest({this.username, this.email, this.address, this.phone});

  Map<String, dynamic> toJson() => {
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
      };
}

class RegisterEmployeeRequest {
  final String username;
  final String email;
  final String password;
  final String? address;
  final String? phone;
  final int? terrainId;

  const RegisterEmployeeRequest({
    required this.username,
    required this.email,
    required this.password,
    this.address,
    this.phone,
    this.terrainId,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (terrainId != null) 'terrainId': terrainId,
      };
}
