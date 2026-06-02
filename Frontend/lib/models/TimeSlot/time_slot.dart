import 'package:Arena/models/summaries.dart';

class TimeSlot {
  final int id;
  final String startTime;
  final String endTime;
  final bool isActive;
  final ReservationSummary? reservation;

  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    this.reservation,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        id: json['id'] as int,
        // Backend stores as snake_case internally but returns camelCase; guard
        // against any legacy null-startTime rows from earlier camelCase POST bugs.
        startTime: (json['startTime'] ?? json['start_time']) as String? ?? '',
        endTime:   (json['endTime']   ?? json['end_time'])   as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        reservation: json['reservation'] != null
            ? ReservationSummary.fromJson(json['reservation'] as Map<String, dynamic>)
            : null,
      );
}

class CreateTimeSlotRequest {
  final int dayPlanId;
  final String startTime;
  final String endTime;

  const CreateTimeSlotRequest({
    required this.dayPlanId,
    required this.startTime,
    required this.endTime,
  });

  // Strapi expects snake_case field names in the request body.
  Map<String, dynamic> toJson() => {
        'data': {
          'day_plan':   dayPlanId,
          'start_time': startTime,
          'end_time':   endTime,
        },
      };
}

class UpdateTimeSlotRequest {
  final String? startTime;
  final String? endTime;
  final bool? isActive;

  const UpdateTimeSlotRequest({this.startTime, this.endTime, this.isActive});

  // Strapi expects snake_case field names in the request body.
  Map<String, dynamic> toJson() => {
        'data': {
          if (startTime != null) 'start_time': startTime,
          if (endTime != null)   'end_time':   endTime,
          if (isActive != null)  'isActive':   isActive,
        },
      };
}
