import 'package:Arena/models/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderUid;
  final String text;
  final MessageType type;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  /// Deserializes from the REST endpoint response.
  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id:        json['id']?.toString() ?? '',
        senderUid: json['senderUid'] as String,
        text:      json['text'] as String,
        type:      MessageType.values.byName((json['type'] as String?) ?? 'text'),
        createdAt: _parseDate(json['createdAt']),
      );

  /// Deserializes from a Firestore DocumentSnapshot (real-time stream).
  factory Message.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Message(
      id:        doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      text:      data['text']      as String? ?? '',
      type:      MessageType.values.byName((data['type'] as String?) ?? 'text'),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  // Handles Firestore Timestamp, ISO-8601 String, and legacy Map format.
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is Map) {
      final s  = (value['_seconds']     as num?)?.toInt() ?? 0;
      final ns = (value['_nanoseconds'] as num?)?.toInt() ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(s * 1000 + ns ~/ 1000000);
    }
    return DateTime.now();
  }
}

class SendMessageRequest {
  final String conversationId;
  final String senderUid;
  final String text;
  final MessageType type;

  const SendMessageRequest({
    required this.conversationId,
    required this.senderUid,
    required this.text,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'senderUid':      senderUid,
        'text':           text,
        'type':           type.name,
      };
}
