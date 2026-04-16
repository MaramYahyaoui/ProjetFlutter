import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/note_model.dart';
import '../../models/homework_model.dart';
import '../../models/emploi.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

/// Service wrapper pour Firebase Firestore et Auth
/// Centralise tous les appels à Firebase pour une meilleure maintenabilité
class FirebaseService {
  final FirebaseFirestore _firestore;
  final fauth.FirebaseAuth _auth;

  FirebaseService({FirebaseFirestore? firestore, fauth.FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? fauth.FirebaseAuth.instance;

  /// Récupère l'ID utilisateur actuellement authentifié
  String? get currentUserId => _auth.currentUser?.uid;

  /// Récupère l'utilisateur actuellement authentifié
  fauth.User? get currentFirebaseUser => _auth.currentUser;

  /// Vérifie si un utilisateur est actuellement authentifié
  bool get isAuthenticated => _auth.currentUser != null;

  // ============ USER MANAGEMENT ============

  /// Récupère le profil utilisateur depuis Firestore
  Future<User?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) {
        if (kDebugMode) debugPrint('User document not found: $userId');
        return null;
      }

      return User.fromFirestore(doc.data()!, userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  /// Crée ou met à jour le profil utilisateur dans Firestore
  Future<void> setUserProfile(String userId, User user) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error setting user profile: $e');
      rethrow;
    }
  }

  // ============ NOTES ============

  /// Récupère les notes d'un étudiant
  Future<List<Note>> getNotes(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.notes)
          .where(FirebaseFields.studentId, isEqualTo: studentId)
          .orderBy(FirebaseFields.date, descending: true)
          .get();

      return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting notes: $e');
      rethrow;
    }
  }

  // ============ HOMEWORKS ============

  /// Récupère les devoirs
  Future<List<Homework>> getHomeworks() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.homeworks)
          .get();

      final homeworks = snapshot.docs
          .map((doc) => Homework.fromFirestore(doc))
          .toList();

      // Tri par date limite
      homeworks.sort((a, b) => a.dateLimite.compareTo(b.dateLimite));

      return homeworks;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting homeworks: $e');
      rethrow;
    }
  }

  /// Met à jour le statut d'un devoir
  Future<void> updateHomeworkStatus(String homeworkId, bool isCompleted) async {
    try {
      await _firestore
          .collection(FirebaseCollections.homeworks)
          .doc(homeworkId)
          .update({FirebaseFields.isCompleted: isCompleted});
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating homework status: $e');
      rethrow;
    }
  }

  // ============ SCHEDULES ============

  /// Récupère l'emploi du temps d'une classe
  Future<List<Schedule>> getSchedules(String? classe) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.schedules)
          .get();

      final schedules = <Schedule>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final schedule = Schedule.fromFirestore(doc);

        final docClasse = (data[FirebaseFields.classe] ?? data['class'])
            ?.toString()
            .trim();
        final myClasse = (classe ?? '').trim();

        // Filtre par classe
        if (myClasse.isNotEmpty &&
            (docClasse?.isNotEmpty ?? false) &&
            docClasse != myClasse) {
          continue;
        }

        schedules.add(schedule);
      }

      // Tri par jour et heure
      schedules.sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek) {
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        }
        return a.startTime.compareTo(b.startTime);
      });

      return schedules;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting schedules: $e');
      rethrow;
    }
  }

  // ============ CLASS/CLASSE ============

  /// Récupère la classe de l'utilisateur
  Future<String?> getUserClasse(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final classe = (data[FirebaseFields.classe] ?? data['class'])
          ?.toString()
          .trim();

      return (classe?.isEmpty ?? true) ? null : classe;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting user classe: $e');
      rethrow;
    }
  }

  // ============ BATCH OPERATIONS ============

  /// Met à jour la photo de profil d'un utilisateur
  Future<void> updateUserProfilePhoto(
    String userId,
    String photoDataUrl,
  ) async {
    try {
      await _firestore.collection(FirebaseCollections.users).doc(userId).update(
        {'photoPath': photoDataUrl},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating profile photo: $e');
      rethrow;
    }
  }

  /// Récupère tous les profils utilisateurs d'une classe
  Future<List<User>> getClassUsers(String classe) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where(FirebaseFields.classe, isEqualTo: classe)
          .get();

      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting class users: $e');
      rethrow;
    }
  }

  /// Récupère les utilisateurs par rôle
  Future<List<User>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where(FirebaseFields.role, isEqualTo: role)
          .get();

      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting users by role: $e');
      rethrow;
    }
  }

  // ============ MESSAGING ============

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection(FirebaseCollections.conversations);

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String conversationId,
  ) {
    return _conversationsRef
        .doc(conversationId)
        .collection(FirebaseCollections.messages);
  }

  String _conversationId(String userAId, String userBId) {
    final ids = [userAId, userBId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<Conversation>> streamConversations(String userId) {
    return _conversationsRef
        .where(FirebaseFields.participants, arrayContains: userId)
        .orderBy(FirebaseFields.updatedAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Conversation.fromFirestore(doc))
              .toList(),
        );
  }

  Future<String> getOrCreateConversation({
    required User currentUser,
    required User otherUser,
  }) async {
    final conversationId = _conversationId(currentUser.id, otherUser.id);
    final docRef = _conversationsRef.doc(conversationId);
    final existing = await docRef.get();

    if (!existing.exists) {
      final now = FieldValue.serverTimestamp();
      await docRef.set({
        FirebaseFields.participants: [currentUser.id, otherUser.id],
        FirebaseFields.participantNames: {
          currentUser.id: currentUser.fullName,
          otherUser.id: otherUser.fullName,
        },
        FirebaseFields.unreadCounts: {currentUser.id: 0, otherUser.id: 0},
        'studentId': currentUser.role == UserRoles.student
            ? currentUser.id
            : (otherUser.role == UserRoles.student ? otherUser.id : null),
        'teacherId': currentUser.role == UserRoles.teacher
            ? currentUser.id
            : (otherUser.role == UserRoles.teacher ? otherUser.id : null),
        FirebaseFields.lastMessage: '',
        FirebaseFields.lastSenderId: null,
        FirebaseFields.lastMessageAt: null,
        FirebaseFields.createdAt: now,
        FirebaseFields.updatedAt: now,
      });
    }

    return conversationId;
  }

  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _messagesRef(conversationId)
        .orderBy(FirebaseFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required User sender,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final convRef = _conversationsRef.doc(conversationId);

    await _firestore.runTransaction((transaction) async {
      final convSnap = await transaction.get(convRef);
      if (!convSnap.exists) {
        throw Exception('Conversation introuvable');
      }

      final convData = convSnap.data() ?? <String, dynamic>{};
      final participants = List<String>.from(
        convData[FirebaseFields.participants] ?? const [],
      );
      if (!participants.contains(sender.id)) {
        throw Exception('Utilisateur non autorise dans cette conversation');
      }

      final unread = Map<String, int>.from(
        (convData[FirebaseFields.unreadCounts] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            ) ??
            <String, int>{},
      );

      for (final participantId in participants) {
        if (participantId == sender.id) {
          unread[participantId] = 0;
        } else {
          unread[participantId] = (unread[participantId] ?? 0) + 1;
        }
      }

      final messageRef = _messagesRef(conversationId).doc();
      transaction.set(messageRef, {
        'conversationId': conversationId,
        FirebaseFields.senderId: sender.id,
        FirebaseFields.senderName: sender.fullName,
        FirebaseFields.text: trimmed,
        FirebaseFields.createdAt: FieldValue.serverTimestamp(),
      });

      transaction.update(convRef, {
        FirebaseFields.lastMessage: trimmed,
        FirebaseFields.lastSenderId: sender.id,
        FirebaseFields.lastMessageAt: FieldValue.serverTimestamp(),
        FirebaseFields.updatedAt: FieldValue.serverTimestamp(),
        FirebaseFields.unreadCounts: unread,
      });
    });
  }

  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        '${FirebaseFields.unreadCounts}.$userId': 0,
        FirebaseFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error marking conversation as read: $e');
      rethrow;
    }
  }
}
