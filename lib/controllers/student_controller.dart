import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/note_model.dart';
import '../models/homework_model.dart';
import '../models/emploi.dart';

class StudentController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _uid;

  StudentController(this._uid);

  String? _myClasse;
  String? _firstName;
  String? _lastName;
  String? _displayName;

  String get myClasse => _myClasse ?? '';
  String get firstName => _firstName ?? '';
  String get lastName => _lastName ?? '';
  String get displayName {
    final dn = (_displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final fn = (_firstName ?? '').trim();
    final ln = (_lastName ?? '').trim();
    final full = [fn, ln].where((p) => p.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    return FirebaseAuth.instance.currentUser?.email ?? _uid;
  }

  List<Note> _notes = [];
  List<Homework> _homeworks = [];
  Map<String, List<Schedule>> _schedules = {};

  final Map<String, bool> _homeworkCompletionById = {};
  final Map<String, Map<String, dynamic>> _homeworkSubmissionFileById = {};

  List<Note> get notes => _notes;
  List<Homework> get homeworks => _homeworks;
  Map<String, List<Schedule>> get schedules => _schedules;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Initialise les données de l'étudiant
  /// À appeler après l'authentification
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadProfile(),
        loadNotes(),
        loadHomeworks(),
        loadSchedules(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadProfile(),
        loadNotes(),
        loadHomeworks(),
        loadSchedules(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    Future<Map<String, dynamic>?> readUser(String collection) async {
      final doc = await _firestore.collection(collection).doc(_uid).get();
      return doc.data();
    }

    final data = await readUser('utilisateurs') ?? await readUser('users');
    if (data == null) return;

    _firstName = (data['prenom'] as String?)?.trim();
    _lastName = (data['nom'] as String?)?.trim();
    _displayName =
        (data['displayName'] as String?)?.trim() ??
        (data['name'] as String?)?.trim();

    _myClasse ??= (data['classe'] ?? data['class'])?.toString().trim();
    notifyListeners();
  }

  Future<void> loadNotes() async {
    final snapshot = await _firestore
        .collection('notes')
        .where('eleveId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .get();

    _notes = snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
  }

  Future<void> loadHomeworks() async {
    // 1) Load assignments
    final snapshot = await _firestore.collection('devoirs').get();
    final homeworks = snapshot.docs
        .map((doc) => Homework.fromFirestore(doc))
        .toList(growable: false);

    // 2) Load per-student completion status
    final rendusSnap = await _firestore
        .collection('rendus_devoirs')
        .where('eleveId', isEqualTo: _uid)
        .get();

    _homeworkCompletionById
      ..clear()
      ..addEntries(
        rendusSnap.docs
            .map((d) {
              final data = d.data();
              final devoirId = (data['devoirId'] as String?)?.trim();
              final estRendu = (data['estRendu'] as bool?) ?? false;
              if (devoirId == null || devoirId.isEmpty) {
                return const MapEntry<String, bool>('', false);
              }
              return MapEntry(devoirId, estRendu);
            })
            .where((e) => e.key.isNotEmpty),
      );

    _homeworkSubmissionFileById.clear();
    for (final d in rendusSnap.docs) {
      final data = d.data();
      final devoirId = (data['devoirId'] as String?)?.trim();
      if (devoirId == null || devoirId.isEmpty) continue;

      final fichier = data['fichier'];
      if (fichier is Map<String, dynamic>) {
        _homeworkSubmissionFileById[devoirId] = fichier;
      } else if (fichier is Map) {
        _homeworkSubmissionFileById[devoirId] = Map<String, dynamic>.from(
          fichier,
        );
      }
    }

    // 3) Merge status into the in-memory list
    _homeworks = homeworks
        .map(
          (hw) => _withCompletion(hw, _homeworkCompletionById[hw.id] ?? false),
        )
        .toList(growable: true);

    // Sort by dateLimite in memory
    _homeworks.sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
  }

  Homework _withCompletion(Homework hw, bool estRendu) {
    if (hw.estRendu == estRendu) return hw;
    return Homework(
      id: hw.id,
      classe: hw.classe,
      matiere: hw.matiere,
      titre: hw.titre,
      description: hw.description,
      dateLimite: hw.dateLimite,
      estRendu: estRendu,
    );
  }

  Future<void> loadSchedules() async {
    try {
      _myClasse ??= await _loadMyClasse();
      final snapshot = await _firestore.collection('emplois').get();

      final Map<String, List<Schedule>> grouped = {};
      const days = [
        '',
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche',
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = (data['type'] ?? '').toString().trim().toLowerCase();
        if (type.isNotEmpty && type != 'eleve') {
          continue;
        }

        final classe = (data['classe'] ?? data['class']).toString().trim();
        final myClasse = (_myClasse ?? '').trim();
        final normalizedClasse = classe.toLowerCase();
        final normalizedMyClasse = myClasse.toLowerCase();
        if (normalizedMyClasse.isNotEmpty &&
            normalizedClasse.isNotEmpty &&
            normalizedClasse != normalizedMyClasse) {
          continue;
        }

        // Les données réelles d'un créneau peuvent être stockées dans le champ
        // map 'creneaux' (structure utilisée par la page admin).
        final creneauxRaw = data['creneaux'];
        final creneaux = creneauxRaw is Map
            ? Map<String, dynamic>.from(creneauxRaw)
            : <String, dynamic>{};

        final mergedData = <String, dynamic>{
          ...data,
          if (creneaux.isNotEmpty) ...creneaux,
          // On garde le jour depuis le document parent si présent.
          'jour_semaine': data['jour_semaine'] ?? creneaux['jour_semaine'],
        };

        final schedule = _scheduleFromData(doc.id, mergedData);
        if (schedule.subject.trim().isEmpty) {
          continue;
        }

        final ownerId = (schedule.ownerId ?? '').trim();
        if (classe.isEmpty && ownerId.isNotEmpty && ownerId != _uid) {
          continue;
        }

        final dayName = days[schedule.dayOfWeek];
        grouped.putIfAbsent(dayName, () => []);
        grouped[dayName]!.add(schedule);
      }

      // Sort schedules by time within each day
      for (var day in grouped.keys) {
        grouped[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      _schedules = grouped;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading schedules: $e');
      }
    }
  }

  Schedule _scheduleFromData(String id, Map<String, dynamic> data) {
    return Schedule(
      id: id,
      subject: (data['matiere'] ?? '').toString().trim(),
      teacher: (data['professeur'] ?? '').toString().trim(),
      classroom: (data['salle'] ?? '').toString().trim(),
      dayOfWeek: _parseDayOfWeek(data['jour_semaine'] ?? data['jour_semain']),
      startTime: (data['debut'] ?? '08:00').toString().trim(),
      endTime: (data['fin'] ?? '10:00').toString().trim(),
      type: (data['type'] ?? 'eleve').toString().trim(),
      ownerId: (data['ownerId'] ?? data['eleveId'] ?? data['professeurId'])
          ?.toString()
          .trim(),
      color: data['color']?.toString(),
    );
  }

  int _parseDayOfWeek(dynamic value) {
    if (value is int && value >= 1 && value <= 7) {
      return value;
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null && parsed >= 1 && parsed <= 7) {
      return parsed;
    }
    return 1;
  }

  Future<String?> _loadMyClasse() async {
    // IMPORTANT:
    // On doit pouvoir charger la classe pour l'UID ciblé par ce controller,
    // pas uniquement pour l'utilisateur Firebase "courant".
    // (ex: espace parent → lecture des données d'un enfant)
    final uid = _uid.trim();
    if (uid.isEmpty) return null;

    Future<String?> readClasse(String collection) async {
      final doc = await _firestore.collection(collection).doc(uid).get();
      final data = doc.data();
      if (data == null) return null;
      final raw = (data['classe'] ?? data['class']).toString().trim();
      return raw.isEmpty ? null : raw;
    }

    return await readClasse('utilisateurs') ?? await readClasse('users');
  }

  double getAverage() {
    if (_notes.isEmpty) return 0;
    final sum = _notes.fold<double>(0, (sum, n) => sum + n.percentage);
    return sum / _notes.length;
  }

  List<Homework> getPendingHomeworks() =>
      _homeworks.where((hw) => !hw.isCompleted).toList();

  List<Homework> getCompletedHomeworks() =>
      _homeworks.where((hw) => hw.isCompleted).toList();

  Map<String, dynamic>? getHomeworkSubmissionFile(String devoirId) {
    return _homeworkSubmissionFileById[devoirId];
  }

  Future<void> setHomeworkSubmission({
    required String devoirId,
    bool? estRendu,
    Map<String, dynamic>? fichier,
  }) async {
    final docId = '${devoirId}_$_uid';
    final payload = <String, dynamic>{
      'devoirId': devoirId,
      'eleveId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (estRendu != null) payload['estRendu'] = estRendu;
    if (fichier != null) payload['fichier'] = fichier;

    await _firestore
        .collection('rendus_devoirs')
        .doc(docId)
        .set(payload, SetOptions(merge: true));

    if (estRendu != null) {
      _homeworkCompletionById[devoirId] = estRendu;
      final idx = _homeworks.indexWhere((h) => h.id == devoirId);
      if (idx != -1) {
        _homeworks[idx] = _withCompletion(_homeworks[idx], estRendu);
      }
    }

    if (fichier != null) {
      _homeworkSubmissionFileById[devoirId] = fichier;
    }

    notifyListeners();
  }

  Future<void> cancelHomeworkSubmission({required String devoirId}) async {
    final docId = '${devoirId}_$_uid';
    final docRef = _firestore.collection('rendus_devoirs').doc(docId);

    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.update({
        'estRendu': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'fichier': FieldValue.delete(),
      });
    } else {
      // Si le doc n'existe pas, on crée juste un rendu "non remis" sans fichier.
      await docRef.set({
        'devoirId': devoirId,
        'eleveId': _uid,
        'estRendu': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    _homeworkCompletionById[devoirId] = false;
    _homeworkSubmissionFileById.remove(devoirId);

    final idx = _homeworks.indexWhere((h) => h.id == devoirId);
    if (idx != -1) {
      _homeworks[idx] = _withCompletion(_homeworks[idx], false);
    }

    notifyListeners();
  }

  void toggleHomeworkStatus(String id) async {
    final index = _homeworks.indexWhere((hw) => hw.id == id);
    if (index != -1) {
      final newValue = !_homeworks[index].isCompleted;

      await setHomeworkSubmission(devoirId: id, estRendu: newValue);
    }
  }

  Future<void> addHomework({
    required String matiere,
    required String titre,
    required String description,
    required DateTime dateLimite,
    String? attachmentName,
    String? attachmentType,
    int? attachmentSize,
  }) async {
    // Get user's class from Firestore or use a default
    final userDoc = await _firestore.collection('users').doc(_uid).get();
    final userData = userDoc.data();
    final classe = userData?['classe'] ?? 'Default Class';

    // Build fichier map if attachment exists
    Map<String, dynamic>? fichier;
    if (attachmentName != null) {
      fichier = {
        'nom': attachmentName,
        'url': '', // No URL since we're not using Firebase Storage
        'type': attachmentType ?? 'application/octet-stream',
        'taille': attachmentSize ?? 0,
      };
    }

    final docRef = await _firestore.collection('devoirs').add({
      'classe': classe,
      'matiere': matiere,
      'titre': titre,
      'description': description,
      'dateLimite': Timestamp.fromDate(dateLimite),
      'estRendu': false,
      if (fichier != null) 'fichier': fichier,
    });

    // Add to local list
    final newHomework = Homework(
      id: docRef.id,
      classe: classe,
      matiere: matiere,
      titre: titre,
      description: description,
      dateLimite: Timestamp.fromDate(dateLimite),
      estRendu: false,
    );

    _homeworks.insert(0, newHomework);
    _homeworks.sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
    notifyListeners();
  }
}
