import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class WeekAgendaService {
  final ApiService _api;

  WeekAgendaService(this._api);

  // ── Player / shared ───────────────────────────────────────────────────────

  /// GET /week-agendas/available-slots?campusId=&terrainType=&date=
  /// Returns DayPlan-shaped objects with time_slots already filtered to isActive=true.
  /// Only Published agendas surface here.
  Future<List<DayPlan>> getAvailableSlots({
    required int campusId,
    required TerrainType terrainType,
    required String date, // YYYY-MM-DD
  }) async {
    try {
      final response = await _api.get(
        '/week-agendas/available-slots?campusId=$campusId&terrainType=${terrainType.name}&date=$date',
      );
      return (response.data as List<dynamic>)
          .map((e) => DayPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /week-agendas/terrain?campusId=&terrainType=
  /// Full week agenda for a specific terrain (Published only for players).
  Future<WeekAgenda> getTerrainAgenda({
    required int campusId,
    required TerrainType terrainType,
  }) async {
    try {
      final response = await _api.get(
        '/week-agendas/terrain?campusId=$campusId&terrainType=${terrainType.name}',
      );
      return WeekAgenda.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /week-agendas/:id — wrapper: json['agenda']
  Future<WeekAgenda> getWeekAgenda(int id) async {
    try {
      final response = await _api.get('/week-agendas/$id');
      final data = response.data as Map<String, dynamic>;
      return WeekAgenda.fromJson(data['agenda'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /time-slots?day_plan=&isActive= — wrapper: json['data'].
  Future<List<TimeSlot>> getTimeSlots({int? dayPlanId, bool? isActive}) async {
    try {
      final params = StringBuffer('/time-slots?');
      if (dayPlanId != null) params.write('day_plan=$dayPlanId&');
      if (isActive != null) params.write('isActive=$isActive');
      final response = await _api.get(params.toString());
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data
          .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  // ── Manager ───────────────────────────────────────────────────────────────

  /// POST /manager/week-agendas — auto-creates 7 DayPlans + default TimeSlots.
  Future<WeekAgenda> createWeekAgenda(CreateWeekAgendaRequest request) async {
    try {
      final response = await _api.post('/manager/week-agendas', request.toJson());
      // Response: {"message":"...", "agenda":{...}}
      final data = response.data as Map<String, dynamic>;
      return WeekAgenda.fromJson(data['agenda'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /manager/week-agendas/:id/publish — makes the agenda visible to players.
  Future<void> publishWeekAgenda(int id) async {
    try {
      await _api.post('/manager/week-agendas/$id/publish', null);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// DELETE /manager/week-agendas/:id — removes agenda and all related day plans/slots.
  Future<void> deleteWeekAgenda(int id) async {
    try {
      await _api.delete('/manager/week-agendas/$id');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /manager/day-plans/:id — update dayType / notes.
  /// NOTE: backend currently returns 405; add the route on the backend to enable.
  Future<void> updateDayPlan(int dayPlanId, {
    required DayType dayType,
    String? notes,
  }) async {
    final body = {
      'dayType': switch (dayType) {
        DayType.normal      => 'normal',
        DayType.urgent_only => 'urgent_only',
        DayType.day_off     => 'day_off',
      },
      if (notes case final n?) 'notes': n,
    };
    try {
      await _api.put('/manager/day-plans/$dayPlanId', body);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /manager/day-plans/:id — returns day plan with time_slots embedded.
  Future<DayPlan> getDayPlanById(int id) async {
    try {
      final response = await _api.get('/manager/day-plans/$id');
      return DayPlan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// DELETE /manager/day-plans/:id — removes the day plan and all its time slots.
  Future<void> deleteDayPlan(int id) async {
    try {
      await _api.delete('/manager/day-plans/$id');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /manager/day-plans/by-date?date=&campusId=
  Future<List<DayPlan>> getDayPlansByDate({
    required String date, // YYYY-MM-DD
    required int campusId,
  }) async {
    try {
      final response = await _api.get(
        '/manager/day-plans/by-date?date=$date&campusId=$campusId',
      );
      return (response.data as List<dynamic>)
          .map((e) => DayPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /manager/day-plans
  Future<DayPlan> createDayPlan(CreateDayPlanRequest request) async {
    try {
      final response = await _api.post('/manager/day-plans', request.toJson());
      return DayPlan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /time-slots
  Future<TimeSlot> createTimeSlot(CreateTimeSlotRequest request) async {
    try {
      final response = await _api.post('/time-slots', request.toJson());
      return TimeSlot.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /time-slots/:id
  Future<TimeSlot> updateTimeSlot(int id, UpdateTimeSlotRequest request) async {
    try {
      final response = await _api.put('/time-slots/$id', request.toJson());
      return TimeSlot.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// DELETE /time-slots/:id
  Future<void> deleteTimeSlot(int id) async {
    try {
      await _api.delete('/time-slots/$id');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
