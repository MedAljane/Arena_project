// ignore_for_file: constant_identifier_names
// Lightweight relation stubs — used when a model is nested inside another to
// avoid circular imports and keep payloads small.

import 'package:Arena/models/enums.dart';

class CampusSummary {
  final int id;
  final String name;

  const CampusSummary({required this.id, required this.name});

  factory CampusSummary.fromJson(Map<String, dynamic> json) =>
      CampusSummary(id: json['id'] as int, name: json['Name'] as String);
}

class TerrainSummary {
  final int id;
  final TerrainType type;

  const TerrainSummary({required this.id, required this.type});

  factory TerrainSummary.fromJson(Map<String, dynamic> json) => TerrainSummary(
        id: json['id'] as int,
        type: TerrainType.values.byName(json['Type'] as String),
      );
}

class ManagerSummary {
  final int id;
  final String? nom;

  const ManagerSummary({required this.id, this.nom});

  factory ManagerSummary.fromJson(Map<String, dynamic> json) =>
      ManagerSummary(id: json['id'] as int, nom: json['nom'] as String?);
}

class EmployeeSummary {
  final int id;
  final String? username;

  const EmployeeSummary({required this.id, this.username});

  factory EmployeeSummary.fromJson(Map<String, dynamic> json) =>
      EmployeeSummary(id: json['id'] as int, username: json['username'] as String?);
}

class PlayerSummary {
  final int id;
  final String? nom;

  const PlayerSummary({required this.id, this.nom});

  factory PlayerSummary.fromJson(Map<String, dynamic> json) =>
      PlayerSummary(id: json['id'] as int, nom: json['nom'] as String?);
}

class ReservationSummary {
  final int id;
  final ReservationStatus statu;

  const ReservationSummary({required this.id, required this.statu});

  factory ReservationSummary.fromJson(Map<String, dynamic> json) =>
      ReservationSummary(
        id: json['id'] as int,
        statu: ReservationStatus.values.byName(json['statu'] as String),
      );
}

class TimeSlotSummary {
  final int id;
  final String startTime;
  final String endTime;
  // Populated when day_plan is included in the response (e.g. reservations/mine).
  final String? slotDate;    // "2026-06-18"
  final String? dayOfWeek;   // "Wednesday"

  const TimeSlotSummary({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.slotDate,
    this.dayOfWeek,
  });

  factory TimeSlotSummary.fromJson(Map<String, dynamic> json) {
    final dp = json['day_plan'] as Map<String, dynamic>?;
    return TimeSlotSummary(
      id:        json['id'] as int,
      startTime: json['startTime'] as String,
      endTime:   json['endTime'] as String,
      slotDate:  dp?['date'] as String?,
      dayOfWeek: dp?['dayOfWeek'] as String?,
    );
  }
}

class WeekAgendaSummary {
  final int id;
  final String weekStartDate;
  final WeekAgendaStatus statu;

  const WeekAgendaSummary({
    required this.id,
    required this.weekStartDate,
    required this.statu,
  });

  factory WeekAgendaSummary.fromJson(Map<String, dynamic> json) =>
      WeekAgendaSummary(
        id: json['id'] as int,
        weekStartDate: json['weekStartDate'] as String,
        statu: WeekAgendaStatus.values.byName(json['statu'] as String),
      );
}
