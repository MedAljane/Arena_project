import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/ai/ai_chat.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class AiService {
  final ApiService _api;
  AiService(this._api);

  /// POST /ai/player-chat
  /// [sessionId] groups all turns in the same conversation for analytics.
  /// Generate once when the screen opens and pass it with every turn.
  Future<AiChatResponse> playerChat(
      String message, List<AiChatMessage> history, String sessionId) async {
    try {
      final response = await _api.post('/ai/player-chat', {
        'message':   message,
        'history':   history.map((m) => m.toHistoryJson()).toList(),
        'sessionId': sessionId,
      });
      return AiChatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// POST /ai/manager-chat
  Future<AiChatResponse> managerChat(
      String message, List<AiChatMessage> history, String sessionId) async {
    try {
      final response = await _api.post('/ai/manager-chat', {
        'message':   message,
        'history':   history.map((m) => m.toHistoryJson()).toList(),
        'sessionId': sessionId,
      });
      return AiChatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
