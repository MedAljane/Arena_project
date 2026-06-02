import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class PlayerService {
  final ApiService _api;

  PlayerService(this._api);

  /// GET /player/me — returns the authenticated player's full profile.
  Future<Player> getMe() async {
    try {
      final response = await _api.get('/player/me');
      return Player.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// PUT /player/me — updates the player's profile and returns the updated entity.
  Future<Player> updateProfile(UpdatePlayerRequest request) async {
    try {
      final response = await _api.put('/player/me', request.toJson());
      final data = response.data as Map<String, dynamic>;
      return Player.fromJson(data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
