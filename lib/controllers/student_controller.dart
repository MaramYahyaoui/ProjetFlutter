import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/note_model.dart';
import '../models/homework_model.dart';
import '../models/emploi.dart';

class StudentController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

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

  List<Note> get notes => _notes;
  List<Homework> get homeworks => _homeworks;
  Map<String, List<Schedule>> get schedules => _schedules;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StudentController() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadProfile(),
      loadNotes(),
      loadHomeworks(),
      loadSchedules(),
    ]);

    _isLoading = false;
    notifyListeners();
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
    final snapshot = await _firestore.collection('devoirs').get();

    _homeworks = snapshot.docs
        .map((doc) => Homework.fromFirestore(doc))
        .toList();

    // Sort by dateLimite in memory
    _homeworks.sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
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
        final schedule = Schedule.fromFirestore(doc);

        final classe = (data['classe'] ?? data['class']).toString().trim();
        final myClasse = (_myClasse ?? '').trim();
        if (myClasse.isNotEmpty && classe.isNotEmpty && classe != myClasse) {
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

  Future<String?> _loadMyClasse() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

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

  void toggleHomeworkStatus(String id) async {
    final index = _homeworks.indexWhere((hw) => hw.id == id);
    if (index != -1) {
      final newValue = !_homeworks[index].isCompleted;

      await _firestore.collection('devoirs').doc(id).update({
        'estRendu': newValue,
      });

      _homeworks[index] = Homework(
        id: _homeworks[index].id,
        classe: _homeworks[index].classe,
        matiere: _homeworks[index].matiere,
        titre: _homeworks[index].titre,
        description: _homeworks[index].description,
        dateLimite: _homeworks[index].dateLimite,
        estRendu: newValue,
      );

      notifyListeners();
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
