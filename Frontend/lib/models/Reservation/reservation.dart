import 'package:Arena/models/enums.dart';
import 'package:Arena/models/summaries.dart';

class Reservation {
  final int id;
  final ReservationType type;
  // Field is intentionally "statu" (not "status") — baked into the DB schema.
  final ReservationStatus statu;
  final String? notes;
  final DateTime? bookedAt;
  final TerrainSummary? terrain;
  final TimeSlotSummary? timeSlot;
  final PlayerSummary? player;
  final ManagerSummary? manager;

  const Reservation({
    required this.id,
    required this.type,
    required this.statu,
    this.notes,
    this.bookedAt,
    this.terrain,
    this.timeSlot,
    this.player,
    this.manager,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as int,
        type: ReservationType.values.byName(json['type'] as String),
        statu: ReservationStatus.values.byName(json['statu'] as String),
        notes: json['notes'] as String?,
        bookedAt: json['bookedAt'] != null
            ? DateTime.parse(json['bookedAt'] as String)
            : null,
        terrain: json['terrain'] != null
            ? TerrainSummary.fromJson(json['terrain'] as Map<String, dynamic>)
            : null,
        timeSlot: json['time_slot'] != null
            ? TimeSlotSummary.fromJson(json['time_slot'] as Map<String, dynamic>)
            : null,
        player: json['player'] != null
            ? PlayerSummary.fromJson(json['player'] as Map<String, dynamic>)
            : null,
        manager: json['manager'] != null
            ? ManagerSummary.fromJson(json['manager'] as Map<String, dynamic>)
            : null,
      );
}

class CreateReservationRequest {
  final int timeSlotId;
  final int campusId;
  final int terrainId;
  final int? managerId;
  final ReservationType type;
  final String? notes;

  const CreateReservationRequest({
    required this.timeSlotId,
    required this.campusId,
    required this.terrainId,
    this.managerId,
    required this.type,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'timeSlotId': timeSlotId,
        'campusId': campusId,
        'terrainId': terrainId,
        if (managerId != null) 'managerId': managerId,
        'type': type.name,
        if (notes != null) 'notes': notes,
      };
}

class UpdateReservationRequest {
  final ReservationType? type;
  final String? notes;

  const UpdateReservationRequest({this.type, this.notes});

  Map<String, dynamic> toJson() => {
        'data': {
          if (type != null) 'type': type!.name,
          if (notes != null) 'notes': notes,
        },
      };
}
