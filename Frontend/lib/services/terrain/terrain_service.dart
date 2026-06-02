import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class TerrainService {
  final ApiService _api;

  TerrainService(this._api);

  // ── Player ────────────────────────────────────────────────────────────────

  /// GET /player/get-terrains — all terrains.
  /// Backend wraps: {"terrains": [...]}
  Future<List<Terrain>> getPlayerTerrains() async {
    try {
      final response = await _api.get('/player/get-terrains');
      final data = response.data;
      final list = data is Map
          ? (data['terrains'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      return list.map((e) => Terrain.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /player/get-terrain/:id
  Future<Terrain> getPlayerTerrain(int id) async {
    try {
      final response = await _api.get('/player/get-terrain/$id');
      return Terrain.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  // ── Manager ───────────────────────────────────────────────────────────────

  /// GET /manager/get-terrains — all terrains for the manager's campus.
  Future<List<Terrain>> getManagerTerrains() async {
    try {
      final response = await _api.get('/manager/get-terrains');
      // Backend wraps the list: {"terrains": [...]}
      final data = response.data;
      final list = data is Map ? (data['terrains'] as List<dynamic>? ?? []) : (data as List<dynamic>);
      return list.map((e) => Terrain.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /manager/get-terrain/:id
  Future<Terrain> getManagerTerrain(int id) async {
    try {
      final response = await _api.get('/manager/get-terrain/$id');
      return Terrain.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /manager/create-terrain
  Future<Terrain> createTerrain(TerrainRequest request) async {
    try {
      final response = await _api.post('/manager/create-terrain', request.toJson());
      // Response: {"message":"...", "terrain":{...}}
      final data = response.data as Map<String, dynamic>;
      return Terrain.fromJson(data['terrain'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /manager/update-terrain/:id
  Future<Terrain> updateTerrain(int id, UpdateTerrainRequest request) async {
    try {
      final response = await _api.put('/manager/update-terrain/$id', request.toJson());
      return Terrain.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// DELETE /manager/delete-terrain/:id
  Future<void> deleteTerrain(int id) async {
    try {
      await _api.delete('/manager/delete-terrain/$id');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
