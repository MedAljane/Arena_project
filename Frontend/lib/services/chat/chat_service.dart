// Firestore security rules required for this service to work:
//
//   rules_version = '2';
//   service cloud.firestore {
//     match /databases/{database}/documents {
//       match /conversations/{conversationId} {
//         allow read: if true;
//         match /messages/{messageId} {
//           allow read: if true;
//         }
//       }
//     }
//   }
//
// Writes are handled server-side via the Admin SDK (POST /conversations/:id/messages),
// so the Flutter client only needs read access.

import 'package:Arena/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Real-time stream of messages in [conversationId], ordered oldest-first.
  static Stream<List<Message>> streamMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  /// Real-time stream of the conversation document — used to show the last
  /// message preview in conversation-list tiles.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamConversation(
      String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .snapshots();
  }

  // ── Reservation conversation queries ─────────────────────────────────────

  /// Streams all reservation conversations for a player (by their Strapi
  /// profile ID, stored as a string in [participantsIds.player]).
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamPlayerConversations(
      String playerProfileId) {
    return _db
        .collection('conversations')
        .where('participantsIds.player', isEqualTo: playerProfileId)
        .snapshots();
  }

  /// Streams all reservation conversations for an employee (by their Strapi
  /// profile ID stored in [participantsIds.employee]).
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      streamEmployeeConversations(String employeeProfileId) {
    return _db
        .collection('conversations')
        .where('participantsIds.employee', isEqualTo: employeeProfileId)
        .snapshots();
  }

  // ── One-shot reads ────────────────────────────────────────────────────────

  /// Returns the last message text and timestamp for [conversationId], or
  /// null if no messages have been sent yet.
  static Future<Map<String, dynamic>?> getConversationMeta(
      String conversationId) async {
    final doc = await _db
        .collection('conversations')
        .doc(conversationId)
        .get();
    return doc.data();
  }
}
