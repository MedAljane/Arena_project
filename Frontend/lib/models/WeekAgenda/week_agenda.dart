import 'package:Arena/models/enums.dart';
import 'package:Arena/models/summaries.dart';
import 'package:Arena/models/DayPlan/day_plan.dart';

class WeekAgenda {
  final int id;
  final String weekStartDate;
  // Field is intentionally "statu" (not "status") — baked into the DB schema.
  final WeekAgendaStatus statu;
  final TerrainSummary? terrain;
  final CampusSummary? campus;
  final List<DayPlan> dayPlans;
  // Busyness stored in DB; updated on every reservation.
  final int busyness;        // 0–100 percentage
  final int? totalSlots;
  final int? availableSlots;

  const WeekAgenda({
    required this.id,
    required this.weekStartDate,
    required this.statu,
    this.terrain,
    this.campus,
    this.dayPlans = const [],
    this.busyness = 0,
    this.totalSlots,
    this.availableSlots,
  });

  double get busyRatio => busyness / 100.0;

  factory WeekAgenda.fromJson(Map<String, dynamic> json) => WeekAgenda(
        id: json['id'] as int,
        weekStartDate: json['weekStartDate'] as String,
        statu: WeekAgendaStatus.values.byName(json['statu'] as String),
        terrain: json['terrain'] != null
            ? TerrainSummary.fromJson(json['terrain'] as Map<String, dynamic>)
            : null,
        campus: json['campus'] != null
            ? CampusSummary.fromJson(json['campus'] as Map<String, dynamic>)
            : null,
        dayPlans: (json['day_plans'] as List<dynamic>? ?? [])
            .map((e) => DayPlan.fromJson(e as Map<String, dynamic>))
            .toList(),
        busyness:      (json['busyness'] as num?)?.toInt() ?? 0,
        totalSlots:    (json['totalSlots'] as num?)?.toInt(),
        availableSlots:(json['availableSlots'] as num?)?.toInt(),
      );
}

class CreateWeekAgendaRequest {
  final String weekStartDate;
  final int campusId;
  final TerrainType terrainType;
  // Send terrainId once the backend adds support for per-terrain agenda creation.
  final int? terrainId;

  const CreateWeekAgendaRequest({
    required this.weekStartDate,
    required this.campusId,
    required this.terrainType,
    this.terrainId,
  });

  Map<String, dynamic> toJson() => {
        'weekStartDate': weekStartDate,
        'campusId': campusId,
        'terrainType': terrainType.name,
        if (terrainId != null) 'terrainId': terrainId,
      };
}
