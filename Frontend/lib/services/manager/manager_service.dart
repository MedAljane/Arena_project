import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class ManagerService {
  final ApiService _api;

  ManagerService(this._api);

  /// GET /manager/me — returns the authenticated manager's full profile.
  Future<Manager> getMe() async {
    try {
      final response = await _api.get('/manager/me');
      return Manager.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /manager/me — updates the manager's profile and returns the updated entity.
  Future<Manager> updateProfile(UpdateManagerRequest request) async {
    try {
      final response = await _api.put('/manager/me', request.toJson());
      final data = response.data as Map<String, dynamic>;
      return Manager.fromJson(data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
