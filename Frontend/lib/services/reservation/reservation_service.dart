import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class ReservationService {
  final ApiService _api;

  ReservationService(this._api);

  /// GET /reservations/mine — wrapper: json['data'] (list, newest first).
  Future<List<Reservation>> getMyReservations() async {
    try {
      final response = await _api.get('/reservations/mine');
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data
          .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /reservations — wrapper: json['data'] (single object).
  /// Locks the time slot atomically; throws ServiceException on 400 if the
  /// slot was taken between the player browsing and submitting.
  Future<Reservation> createReservation(CreateReservationRequest request) async {
    try {
      final response = await _api.post('/reservations', request.toJson());
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return Reservation.fromJson(data);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /reservations/:id — update type or notes only.
  Future<Reservation> updateReservation(int id, UpdateReservationRequest request) async {
    try {
      final response = await _api.put('/reservations/$id', request.toJson());
      return Reservation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /reservations/:id/cancel — sets statu=cancelled and re-activates the slot.
  Future<void> cancelReservation(int id) async {
    try {
      await _api.put('/reservations/$id/cancel', null);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  // ── Employee endpoints ────────────────────────────────────────────────────

  /// GET /employee/reservations — all reservations for the employee's terrain.
  Future<List<Reservation>> getEmployeeReservations() async {
    try {
      final response = await _api.get('/employee/reservations');
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  // ── Manager endpoints ─────────────────────────────────────────────────────

  /// GET /manager/reservations/pending — all pending reservations for the manager's terrains.
  Future<List<Reservation>> getPendingReservations() async {
    try {
      final response = await _api.get('/manager/reservations/pending');
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /manager/reservations/:id/confirm — approves the reservation; triggers
  /// the lifecycle that creates the player↔employee conversation.
  Future<Reservation> confirmReservation(int id) async {
    try {
      final response = await _api.put('/manager/reservations/$id/confirm', null);
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return Reservation.fromJson(data);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /manager/reservations/:id/deny — cancels the reservation and reactivates the slot.
  Future<void> denyReservation(int id) async {
    try {
      await _api.put('/manager/reservations/$id/deny', null);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
