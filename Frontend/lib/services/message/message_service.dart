// REST-based messaging service. For real-time updates use the Firebase
// Firestore SDK directly (.snapshots()) — see Message.fromFirestore.
import 'package:Arena/core/servecice/api_service.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/services/service_exception.dart';
import 'package:dio/dio.dart';

class MessageService {
  final ApiService _api;

  MessageService(this._api);

  /// POST /conversations/:conversationId/messages
  /// Backend returns {"success":true} — the new message is delivered via the
  /// Firestore real-time stream, so no parse needed here.
  Future<void> sendMessage(SendMessageRequest request) async {
    try {
      await _api.post(
        '/conversations/${request.conversationId}/messages',
        request.toJson(),
      );
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /conversations/:conversationId/messages — ordered by createdAt asc.
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _api.get('/conversations/$conversationId/messages');
      return (response.data as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// GET /conversations/:conversationId/messages/:messageId
  Future<Message> getMessage(String conversationId, String messageId) async {
    try {
      final response =
          await _api.get('/conversations/$conversationId/messages/$messageId');
      return Message.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }

  /// DELETE /conversations/:conversationId/messages/:messageId
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _api.delete('/conversations/$conversationId/messages/$messageId');
    } on DioException catch (e) {
      throw ServiceException(extractErrorMessage(e));
    }
  }
}
