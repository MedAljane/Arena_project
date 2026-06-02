import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class AdminService {
  final ApiService _api;

  AdminService(this._api);

  /// GET /admin/admins — wrapper: json['result'].
  Future<List<AuthUser>> getAdmins() async {
    try {
      final response = await _api.get('/admin/admins');
      final result = (response.data as Map<String, dynamic>)['result'] as List<dynamic>;
      return result
          .map((e) => AuthUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /admin/managers — wrapper: json['result'].
  Future<List<Manager>> getManagers() async {
    try {
      final response = await _api.get('/admin/managers');
      final result = (response.data as Map<String, dynamic>)['result'] as List<dynamic>;
      return result
          .map((e) => Manager.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /admin/players — wrapper: json['result'].
  Future<List<Player>> getPlayers() async {
    try {
      final response = await _api.get('/admin/players');
      final result = (response.data as Map<String, dynamic>)['result'] as List<dynamic>;
      return result
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /admin/employees — wrapper: json['result'].
  Future<List<Employee>> getEmployees() async {
    try {
      final response = await _api.get('/admin/employees');
      final result = (response.data as Map<String, dynamic>)['result'] as List<dynamic>;
      return result
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /admin/get-all-campuses — plain array.
  Future<List<Campus>> getCampuses() async {
    try {
      final response = await _api.get('/admin/get-all-campuses');
      return (response.data as List<dynamic>)
          .map((e) => Campus.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /admin/terrains — wrapper: json['terrains'].
  Future<List<Terrain>> getTerrains() async {
    try {
      final response = await _api.get('/admin/terrains');
      final terrains =
          (response.data as Map<String, dynamic>)['terrains'] as List<dynamic>;
      return terrains
          .map((e) => Terrain.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /admin/week-agendas — wrapper: json['agendas'].
  Future<List<WeekAgenda>> getWeekAgendas() async {
    try {
      final response = await _api.get('/admin/week-agendas');
      final agendas =
          (response.data as Map<String, dynamic>)['agendas'] as List<dynamic>;
      return agendas
          .map((e) => WeekAgenda.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
