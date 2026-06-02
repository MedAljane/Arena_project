import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class EmployeeService {
  final ApiService _api;

  EmployeeService(this._api);

  // ── Player ────────────────────────────────────────────────────────────────

  /// GET /player/employees — all employees (read-only, for player view).
  Future<List<Employee>> getPlayerEmployees() async {
    try {
      final response = await _api.get('/player/employees');
      return (response.data as List<dynamic>)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /player/managers — all managers (read-only, for player view).
  Future<List<Manager>> getPlayerManagers() async {
    try {
      final response = await _api.get('/player/managers');
      return (response.data as List<dynamic>)
          .map((e) => Manager.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  // ── Manager ───────────────────────────────────────────────────────────────

  /// GET /manager/employees — flat list with user fields merged + terrain field.
  Future<List<Employee>> getManagerEmployees() async {
    try {
      final response = await _api.get('/manager/employees');
      // Backend wraps the list: {"result": [...]}
      final data = response.data;
      final list = data is Map ? (data['result'] as List<dynamic>? ?? []) : (data as List<dynamic>);
      return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /manager/register-employee — creates user + employee profile, optionally assigns terrain.
  Future<void> registerEmployee(RegisterEmployeeRequest request) async {
    try {
      await _api.post('/manager/register-employee', request.toJson());
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /manager/update-employee/:id
  Future<Employee> updateEmployee(int id, UpdateEmployeeRequest request) async {
    try {
      final response = await _api.put('/manager/update-employee/$id', request.toJson());
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// DELETE /manager/delete-employee/:id — removes the employee profile and the linked user account.
  Future<void> deleteEmployee(int id) async {
    try {
      await _api.delete('/manager/delete-employee/$id');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /employee/me — returns the employee's own profile (includes profile ID).
  /// Used by [PlayerChatScreen] when the logged-in user is an employee so it can
  /// filter Firestore conversations by [participantsIds.employee].
  Future<int?> getMyProfileId() async {
    try {
      final response = await _api.get('/employee/me');
      return (response.data as Map<String, dynamic>)['id'] as int?;
    } on DioException catch (_) {
      return null;
    }
  }

  /// POST /manager/assign-employee/:employeeId/terrain/:terrainId
  /// Syncs both terrain.employee and employee.terrain server-side.
  Future<void> assignEmployee({
    required int employeeId,
    required int terrainId,
  }) async {
    try {
      await _api.post(
        '/manager/assign-employee/$employeeId/terrain/$terrainId',
        null,
      );
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
