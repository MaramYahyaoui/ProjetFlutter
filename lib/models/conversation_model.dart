import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, int> unreadCounts;
  final String? studentId;
  final String? teacherId;
  final String lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.unreadCounts,
    this.studentId,
    this.teacherId,
    required this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? const <String>[]),
      participantNames: Map<String, String>.from(
        (data['participantNames'] as Map?) ?? const <String, String>{},
      ),
      unreadCounts: Map<String, int>.from(
        (data['unreadCounts'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            ) ??
            const <String, int>{},
      ),
      studentId: (data['studentId'] as String?)?.trim(),
      teacherId: (data['teacherId'] as String?)?.trim(),
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastSenderId: (data['lastSenderId'] as String?)?.trim(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  String titleFor(String currentUserId) {
    final otherId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    return participantNames[otherId] ?? 'Utilisateur';
  }

  int unreadFor(String userId) => unreadCounts[userId] ?? 0;
}
