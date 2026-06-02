import 'package:Arena/models/enums.dart';
import 'package:Arena/models/summaries.dart';

class Terrain {
  final int id;
  final TerrainType type;
  final CampusSummary? campus;
  final EmployeeSummary? employee;
  final List<WeekAgendaSummary> weekAgenda;

  const Terrain({
    required this.id,
    required this.type,
    this.campus,
    this.employee,
    this.weekAgenda = const [],
  });

  factory Terrain.fromJson(Map<String, dynamic> json) => Terrain(
        id: json['id'] as int,
        type: TerrainType.values.byName(json['Type'] as String),
        campus: json['campus'] != null
            ? CampusSummary.fromJson(json['campus'] as Map<String, dynamic>)
            : null,
        employee: json['employee'] != null
            ? EmployeeSummary.fromJson(json['employee'] as Map<String, dynamic>)
            : null,
        weekAgenda: (json['week_agenda'] as List<dynamic>? ?? [])
            .map((e) => WeekAgendaSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TerrainRequest {
  final TerrainType type;
  final int campusId;
  // Strapi user ID, not employee profile ID.
  final int? employeeId;

  const TerrainRequest({
    required this.type,
    required this.campusId,
    this.employeeId,
  });

  Map<String, dynamic> toJson() => {
        'Type': type.name,
        'campusId': campusId,
        if (employeeId != null) 'employeeId': employeeId,
      };
}

class UpdateTerrainRequest {
  final TerrainType? type;
  final int? campusId;
  // Strapi user ID, not employee profile ID.
  final int? employeeId;

  const UpdateTerrainRequest({this.type, this.campusId, this.employeeId});

  Map<String, dynamic> toJson() => {
        if (type != null) 'Type': type!.name,
        if (campusId != null) 'campusId': campusId,
        if (employeeId != null) 'employeeId': employeeId,
      };
}
