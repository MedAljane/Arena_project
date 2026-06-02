import 'package:Arena/models/enums.dart';
import 'package:Arena/models/TimeSlot/time_slot.dart';

class DayPlan {
  final int id;
  final DayOfWeek dayOfWeek;
  final String date;
  final DayType dayType;
  final String? notes;
  final List<TimeSlot> timeSlots;
  // Busyness stored in DB; updated on every reservation.
  final int busyness;        // 0–100 percentage
  final int? totalSlots;
  final int? availableSlots;

  const DayPlan({
    required this.id,
    required this.dayOfWeek,
    required this.date,
    required this.dayType,
    this.notes,
    this.timeSlots = const [],
    this.busyness = 0,
    this.totalSlots,
    this.availableSlots,
  });

  double get busyRatio => busyness / 100.0;

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        id: json['id'] as int,
        dayOfWeek: DayOfWeek.values.byName(json['dayOfWeek'] as String),
        date: json['date'] as String,
        dayType: _parseDayType(json['dayType'] as String),
        notes: json['notes'] as String?,
        timeSlots: (json['time_slots'] as List<dynamic>? ?? [])
            .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        busyness:      (json['busyness'] as num?)?.toInt() ?? 0,
        totalSlots:    (json['totalSlots'] as num?)?.toInt(),
        availableSlots:(json['availableSlots'] as num?)?.toInt(),
      );

  // DayType.urgent_only contains an underscore, so .byName() fails — use switch.
  static DayType _parseDayType(String value) => switch (value) {
        'normal' => DayType.normal,
        'urgent_only' => DayType.urgent_only,
        'day_off' => DayType.day_off,
        _ => throw FormatException('Unknown dayType: $value'),
      };

  static String _dayTypeToString(DayType dt) => switch (dt) {
        DayType.normal => 'normal',
        DayType.urgent_only => 'urgent_only',
        DayType.day_off => 'day_off',
      };
}

class CreateDayPlanRequest {
  final DayOfWeek dayOfWeek;
  final String date; // YYYY-MM-DD
  final DayType dayType;
  final String? notes;
  // ID of the WeekAgenda this day plan belongs to.
  // The API field name is "week_agendum" (Strapi plural oddity).
  final int weekAgendumId;

  const CreateDayPlanRequest({
    required this.dayOfWeek,
    required this.date,
    required this.dayType,
    this.notes,
    required this.weekAgendumId,
  });

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek.name,
        'date': date,
        'dayType': DayPlan._dayTypeToString(dayType),
        if (notes != null) 'notes': notes,
        'week_agendum': weekAgendumId,
      };
}
