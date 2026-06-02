import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CampusService {
  final ApiService _api;

  CampusService(this._api);

  // ── Player ────────────────────────────────────────────────────────────────

  /// GET /player/get-all-campuses — plain array response.
  Future<List<Campus>> getPlayerCampuses() async {
    try {
      final response = await _api.get('/player/get-all-campuses');
      return (response.data as List<dynamic>)
          .map((e) => Campus.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /player/get-campus/:id
  Future<Campus> getPlayerCampus(int id) async {
    try {
      final response = await _api.get('/player/get-campus/$id');
      return Campus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /player/get-campus-by-manager — campus belonging to the caller's manager.
  Future<Campus> getPlayerCampusByManager() async {
    try {
      final response = await _api.get('/player/get-campus-by-manager');
      return Campus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  // ── Manager ───────────────────────────────────────────────────────────────

  /// GET /manager/get-campus-by-manager — the manager's own campus.
  /// Backend returns an array even for a single campus; we take the first element.
  Future<Campus> getMyCampus() async {
    try {
      final response = await _api.get('/manager/get-campus-by-manager');
      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return Campus.fromJson(data.first as Map<String, dynamic>);
      }
      if (data is Map<String, dynamic>) {
        return Campus.fromJson(data);
      }
      throw ServiceException('No campus found for this manager.');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    } catch (e) {
      throw ServiceException('Failed to parse campus: $e');
    }
  }

  /// GET /manager/get-campuses — all campuses (manager-scoped).
  Future<List<Campus>> getManagerCampuses() async {
    try {
      final response = await _api.get('/manager/get-campuses');
      return (response.data as List<dynamic>)
          .map((e) => Campus.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /manager/get-campus/:id
  Future<Campus> getManagerCampus(int id) async {
    try {
      final response = await _api.get('/manager/get-campus/$id');
      return Campus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// Uploads files to Strapi's /upload endpoint, returns the media IDs.
  Future<List<int>> uploadFiles(List<XFile> files) async {
    try {
      final formData = FormData();
      for (final file in files) {
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ));
      }
      final response = await _api.postMultipart('/upload', formData);
      return (response.data as List).map<int>((e) => e['id'] as int).toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /manager/create-campus
  Future<Campus> createCampus(CampusRequest request) async {
    try {
      final response = await _api.post('/manager/create-campus', request.toJson());
      final data = response.data as Map<String, dynamic>;
      return Campus.fromJson(data['campus'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /manager/update-campus/:id
  Future<Campus> updateCampus(int id, CampusRequest request) async {
    try {
      final response = await _api.put('/manager/update-campus/$id', request.toJson());
      final data = response.data as Map<String, dynamic>;
      return Campus.fromJson(data['campus'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// DELETE /manager/delete-campus/:id
  Future<void> deleteCampus(int id) async {
    try {
      await _api.delete('/manager/delete-campus/$id');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
