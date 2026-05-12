import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/firebase_service.dart';
import '../models/absence_model.dart';
import '../models/emploi.dart';
import '../models/user_model.dart';

/// Gère la logique métier pour les absences
/// Disponible via Provider pour accès depuis l'app
class AbsenceController with ChangeNotifier {
  final FirebaseService _firebaseService;

  AbsenceController({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  // État de l'application
  List<Absence> _absences = [];
  List<Absence> _studentAbsences = [];
  int _absenceCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Absence> get absences => _absences;
  List<Absence> get studentAbsences => _studentAbsences;
  int get absenceCount => _absenceCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Crée une absence par un professeur
  /// [studentId] : ID de l'élève
  /// [subject] : Matière du cours
  /// [date] : Date de l'absence
  /// [startTime] : Heure de début (format HH:mm)
  /// [endTime] : Heure de fin (format HH:mm)
  /// [scheduleId] : ID du cours (optionnel)
  Future<void> createAbsenceForStudent({
    required String studentId,
    required String subject,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? scheduleId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUserId = _firebaseService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final absence = Absence(
        id: '', // Sera généré par Firestore
        studentId: studentId,
        scheduleId: scheduleId,
        subject: subject,
        date: date,
        startTime: startTime,
        endTime: endTime,
        status: 'absent',
        reportedBy: currentUserId,
        createdAt: DateTime.now(),
      );

      await _firebaseService.createAbsence(absence);

      // Créer les notifications (sans bloquer l'enregistrement)
      unawaited(
        _firebaseService.createAbsenceNotifications(
          studentId: studentId,
          subject: subject,
          date: date,
          absenceId: '', // ID sera dans la notification
          reportedById: currentUserId,
        ),
      );

      // Recharger les données
      await refreshAbsences();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur création absence: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une absence automatiquement à partir d'un horaire
  /// Utilisé par le professeur pour marquer un élève absent d'un cours
  Future<void> createAbsenceFromSchedule({
    required String studentId,
    required Schedule schedule,
    DateTime? date,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUserId = _firebaseService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      await _firebaseService.createAbsenceFromSchedule(
        studentId: studentId,
        schedule: schedule,
        teacherId: currentUserId,
        date: date,
      );

      // Créer les notifications (sans bloquer l'enregistrement)
      unawaited(
        _firebaseService.createAbsenceNotifications(
          studentId: studentId,
          subject: schedule.subject,
          date: date ?? DateTime.now(),
          absenceId: '', // ID sera dans la notification
          reportedById: currentUserId,
        ),
      );

      await refreshAbsences();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur création absence auto: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les absences d'une classe (pour professeur/admin)
  Future<void> loadClassAbsences(String classe, {DateTime? fromDate, DateTime? toDate}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _absences = await _firebaseService.getClassAbsences(
        classe,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur chargement absences classe: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les absences d'un professeur (pour admin)
  Future<void> loadTeacherAbsences(String teacherId, {DateTime? fromDate, DateTime? toDate}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _absences = await _firebaseService.getTeacherAbsences(
        teacherId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur chargement absences professeur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère toutes les absences (pour admin)
  Future<void> loadAllAbsences({DateTime? fromDate, DateTime? toDate}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _absences = await _firebaseService.getAllAbsences(
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur chargement toutes absences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les absences d'un élève (pour élève/parent)
  Future<void> loadStudentAbsences(String studentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _studentAbsences = await _firebaseService.getStudentAbsences(studentId);
      _absenceCount = await _firebaseService.getStudentAbsenceCount(studentId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur chargement absences élève: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Justifie une absence
  /// [absenceId] : ID de l'absence
  /// [reason] : Raison de la justification
  Future<void> justifyAbsence(String absenceId, String reason) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.justifyAbsence(absenceId, reason);

      // Recharger les données
      if (_studentAbsences.isNotEmpty) {
        final index = _studentAbsences.indexWhere((a) => a.id == absenceId);
        if (index >= 0) {
          _studentAbsences[index] = _studentAbsences[index].copyWith(
            status: 'justified',
            reason: reason,
            justifiedAt: DateTime.now(),
          );
        }
      }

      if (_absences.isNotEmpty) {
        final index = _absences.indexWhere((a) => a.id == absenceId);
        if (index >= 0) {
          _absences[index] = _absences[index].copyWith(
            status: 'justified',
            reason: reason,
            justifiedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur justification absence: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les absences actuelles
  Future<void> refreshAbsences() async {
    try {
      if (_studentAbsences.isNotEmpty) {
        // Si nous avons des absences étudiants, recharger celles-ci
        final studentId = _studentAbsences.first.studentId;
        await loadStudentAbsences(studentId);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Erreur rafraîchissement absences: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Obtient les statistiques d'absence pour un élève
  Map<String, int> getAbsenceStats(List<Absence> absences) {
    return {
      'total': absences.length,
      'absent': absences.where((a) => a.status == 'absent').length,
      'justified': absences.where((a) => a.status == 'justified').length,
      'late': absences.where((a) => a.status == 'late').length,
    };
  }

  /// Filtre les absences par statut
  List<Absence> filterByStatus(List<Absence> absences, String status) {
    return absences.where((a) => a.status == status).toList();
  }

  /// Filtre les absences par date
  List<Absence> filterByDateRange(
    List<Absence> absences,
    DateTime startDate,
    DateTime endDate,
  ) {
    return absences
        .where((a) =>
            a.date.isAfter(startDate) &&
            a.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();
  }
}
