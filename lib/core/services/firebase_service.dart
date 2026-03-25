import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/note_model.dart';
import '../../models/homework_model.dart';
import '../../models/emploi.dart';

/// Service wrapper pour Firebase Firestore et Auth
/// Centralise tous les appels à Firebase pour une meilleure maintenabilité
class FirebaseService {
  final FirebaseFirestore _firestore;
  final fauth.FirebaseAuth _auth;

  FirebaseService({
    FirebaseFirestore? firestore,
    fauth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
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
      final doc =
          await _firestore.collection(FirebaseCollections.users).doc(userId).get();

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
      final snapshot =
          await _firestore.collection(FirebaseCollections.homeworks).get();

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
      final snapshot =
          await _firestore.collection(FirebaseCollections.schedules).get();

      final schedules = <Schedule>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final schedule = Schedule.fromFirestore(doc);

        final docClasse =
            (data[FirebaseFields.classe] ?? data['class'])?.toString().trim();
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
      final doc =
          await _firestore.collection(FirebaseCollections.users).doc(userId).get();

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
  Future<void> updateUserProfilePhoto(String userId, String photoDataUrl) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'photoPath': photoDataUrl,
      });
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
}
