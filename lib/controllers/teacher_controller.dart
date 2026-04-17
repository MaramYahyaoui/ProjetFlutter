import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_entry_model.dart';
import '../models/emploi.dart';

/// Controller pour la gestion des données professeur
class TeacherController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  TeacherController(this.uid);

  // =============== DONNÉES PROFILE ===============
  String? _firstName;
  String? _lastName;
  String? _displayName;
  String? _email;
  String? _phone;
  String? _photoPath;
  List<String> _subjects = []; // Matières : ex ["Mathématiques", "Physique"]
  List<String> _classes = []; // Classes assignées : ex ["A101", "C12"]

  // =============== DONNÉES NOTES ===============
  List<GradeEntry> _gradeEntries = [];
  GradeStatistics? _currentClassStatistics;
  Map<String, GradeStatistics> _classStatisticsMap = {};
  String? _selectedClass;

  // =============== DONNÉES EMPLOI DE TEMPS ===============
  List<Schedule> _schedules = [];
  Map<int, List<Schedule>> _schedulesByDay = {}; // Grouped by dayOfWeek

  // =============== ÉTATS DE CHARGEMENT ===============
  bool _isLoading = false;
  String? _error;

  // =============== GETTERS ===============

  // Profile getters
  String get firstName => _firstName ?? '';
  String get lastName => _lastName ?? '';
  String get displayName {
    final dn = (_displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final fn = (_firstName ?? '').trim();
    final ln = (_lastName ?? '').trim();
    final full = [fn, ln].where((p) => p.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    return _email ?? uid;
  }

  String get email => _email ?? '';
  String get phone => _phone ?? '';
  String get photoPath => _photoPath ?? '';
  List<String> get subjects => _subjects;

  // Classes getters
  List<String> get classes => _classes;
  String? get selectedClass => _selectedClass;
  int get totalClasses => _classes.length;

  // Grades getters
  List<GradeEntry> get gradeEntries => _gradeEntries;
  GradeStatistics? get currentClassStatistics => _currentClassStatistics;

  // Schedule getters
  List<Schedule> get schedules => _schedules;
  Map<int, List<Schedule>> get schedulesByDay => _schedulesByDay;

  // State getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // =============== METHODS ===============

  /// Initialise les données du professeur à l'authentification
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Charger le profil EN PREMIER
      await loadProfile();
      
      // Puis charger les autres données
      await Future.wait([
        loadGradeEntries(),
        loadSchedules(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur lors de l\'initialisation: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les données
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Charger le profil EN PREMIER
      await loadProfile();
      
      // Puis charger les autres données
      await Future.wait([
        loadGradeEntries(),
        loadSchedules(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge le profil du professeur
  Future<void> loadProfile() async {
    try {
      final doc = await _firestore.collection('utilisateurs').doc(uid).get();
      if (!doc.exists) {
        debugPrint('❌ Profil non trouvé pour UID: $uid');
        return;
      }

      final data = doc.data() ?? {};

      _firstName = (data['prenom'] as String?)?.trim();
      _lastName = (data['nom'] as String?)?.trim();
      _displayName = (data['displayName'] as String?)?.trim() ??
          (data['name'] as String?)?.trim();
      _email = (data['email'] as String?)?.trim();
      _phone = (data['phone'] as String?)?.trim();
      _photoPath = (data['photoPath'] as String?);
      _subjects = List<String>.from((data['matiere'] as List?) ?? []);
      _classes = List<String>.from((data['classes'] as List?) ?? []);

      debugPrint('👤 Profil chargé: firstName=$_firstName, lastName=$_lastName, displayName=$_displayName');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur loadProfile: $e');
    }
  }

  /// Charge les notes saisies par ce professeur
  Future<void> loadGradeEntries() async {
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('profId', isEqualTo: uid)
          .get();

      _gradeEntries = snapshot.docs
          .map((doc) => GradeEntry.fromFirestore(doc.data(), doc.id))
          .toList();

      // Tri en mémoire par date (plus récent d'abord)
      _gradeEntries.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur loadGradeEntries: $e');
    }
  }

  /// Charge l'emploi de temps du professeur
  Future<void> loadSchedules() async {
    try {
      // Charger TOUS les emplois (pas de filtre par type)
      final snapshot = await _firestore
          .collection('emplois')
          .get();

      // Construire les noms possibles du professeur
      final names = <String>[];
      
      final firstName = (_firstName ?? '').trim().toLowerCase();
      final lastName = (_lastName ?? '').trim().toLowerCase();
      final displayName = this.displayName.trim().toLowerCase();
      
      if (firstName.isNotEmpty) names.add(firstName);
      if (lastName.isNotEmpty) names.add(lastName);
      if (displayName.isNotEmpty) names.add(displayName);
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        names.add('$firstName $lastName');
        names.add('$lastName $firstName');
      }

      debugPrint('🔍 TOP: Filtrage emplois avec noms: $names');
      debugPrint('   firstName="$firstName", lastName="$lastName", displayName="$displayName"');
      
      debugPrint('📊 Total emplois en base: ${snapshot.docs.length}');
      
      // Afficher les professeurs disponibles pour le debug
      final allTeachers = snapshot.docs
          .map((doc) => ((doc.data()['professeur'] as String?) ?? '').trim().toLowerCase())
          .toSet()
          .toList();
      debugPrint('👨‍🏫 Professeurs dispo: $allTeachers');
      
      // Debug: afficher les 3 premiers emplois complets
      for (int i = 0; i < snapshot.docs.take(3).length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        debugPrint('   📌 Emploi $i (${doc.id}):');
        debugPrint('      Toutes les clés: ${data.keys.toList()}');
        debugPrint('      professeur="${data['professeur']}", type="${data['type']}"');
        debugPrint('      matiere="${data['matiere']}", salle="${data['salle']}"');
        debugPrint('      jour_semaine=${data['jour_semaine']}, ownerId="${data['ownerId']}"');
        // Afficher TOUTES les clés et valeurs pour debug
        data.forEach((key, value) {
          debugPrint('      $key: $value (type: ${value.runtimeType})');
        });
      }
      
      // Charger les emplois avec leurs subcollections creneaux
      final allSchedules = <Schedule>[];
      
      for (final doc in snapshot.docs) {
        final docData = doc.data();
        final teacher = (docData['professeur'] as String? ?? '').trim();
        
        debugPrint('🔎 Vérification Emploi ${doc.id}: prof="$teacher", ownerId="${docData['ownerId']}"');
        
        // Vérifier si cet emploi correspond au professeur
        final schedTeacher = teacher.toLowerCase();
        final matches = names.any((name) => 
          schedTeacher == name || 
          schedTeacher.contains(name) ||
          name.contains(schedTeacher)
        );
        
        if (!matches && docData['ownerId'] != uid) {
          debugPrint('⏭️ Emploi ${doc.id} ignoré (prof: $teacher, ownerId: ${docData['ownerId']})');
          continue;
        }
        
        debugPrint('✓ Emploi ${doc.id} correspond');
        
        // Vérifier s'il y a un champ creneaux (map imbriquée)
        final creneauxMap = docData['creneaux'] as Map<String, dynamic>?;
        
        if (creneauxMap == null || creneauxMap.isEmpty) {
          // Si pas de creneaux, utiliser les données du document root
          debugPrint('   ↳ Pas de creneaux, utilisant données root');
          final schedule = Schedule.fromFirestore(doc);
          if (schedule.subject.isNotEmpty) {
            allSchedules.add(schedule);
            debugPrint('✅ Schedule créé: ${schedule.subject} (prof: ${schedule.teacher}, jour: ${schedule.dayOfWeek})');
          }
        } else {
          // Si creneaux existe comme map, créer une Schedule
          debugPrint('   ↳ Creneau trouvé: matiere="${creneauxMap['matiere']}", jour=${docData['jour_semaine']}');
          
          // Fusionner les données root avec creneaux
          final mergedData = {
            ...docData,
            'jour_semaine': docData['jour_semaine'], // Garder jour_semaine du root
            'debut': creneauxMap['debut'],
            'fin': creneauxMap['fin'],
            'matiere': creneauxMap['matiere'] ?? docData['matiere'],
            'salle': creneauxMap['salle'] ?? docData['salle'],
            'professeur': creneauxMap['professeur'] ?? docData['professeur'],
          };

          final schedule = _scheduleFromData(doc.id, mergedData);
          allSchedules.add(schedule);
          
          debugPrint('✅ Schedule créé: ${schedule.subject} (prof: ${schedule.teacher}, jour: ${schedule.dayOfWeek}, ${schedule.startTime}-${schedule.endTime})');
        }
      }

      _schedules = allSchedules;

      // Tri en mémoire par jour de semaine et heure de début
      _schedules.sort((a, b) {
        final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });

      // Grouper par jour de la semaine
      _schedulesByDay.clear();
      for (final schedule in _schedules) {
        _schedulesByDay.putIfAbsent(schedule.dayOfWeek, () => []);
        _schedulesByDay[schedule.dayOfWeek]!.add(schedule);
      }

      debugPrint('✅ Emplois chargés: ${_schedules.length} cours trouvés');
      for (int day = 1; day <= 7; day++) {
        if (_schedulesByDay.containsKey(day)) {
          debugPrint('   Jour $day: ${_schedulesByDay[day]!.length} cours');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur loadSchedules: $e');
      debugPrint('   Stack: $e');
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
      type: (data['type'] ?? 'professeur').toString().trim(),
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

  /// Sélectionne une classe et charge ses statistiques
  Future<void> selectClass(String classe) async {
    try {
      _selectedClass = classe;
      await loadClassStatistics(classe);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur selectClass: $e');
    }
  }

  /// Charge les statistiques d'une classe/matière
  Future<void> loadClassStatistics(String classe) async {
    try {
      // Récupérer les matières enseignées dans cette classe
      // Pour simplifier, on prend toutes les notes du professeur
      final classGrades = _gradeEntries;

      if (classGrades.isEmpty) {
        _currentClassStatistics = const GradeStatistics(
          average: 0,
          successRate: 0,
          evaluationCount: 0,
          studentCount: 0,
          minScore: 0,
          maxScore: 0,
        );
      } else {
        final scores = classGrades.map((g) => g.note).toList();
        final average = scores.reduce((a, b) => a + b) / scores.length;
        final successCount = scores.where((s) => s >= 10).length;
        final successRate = scores.isNotEmpty
            ? ((successCount / scores.length) * 100).toDouble()
            : 0.0;
        
        _currentClassStatistics = GradeStatistics(
          average: average,
          successRate: successRate,
          evaluationCount: classGrades.length,
          studentCount: classGrades
              .map((g) => g.eleveId)
              .toSet()
              .length, // Nombre d'élèves distincts
          minScore: scores.reduce((a, b) => a < b ? a : b),
          maxScore: scores.reduce((a, b) => a > b ? a : b),
        );
      }

      _classStatisticsMap[classe] = _currentClassStatistics!;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur loadClassStatistics: $e');
    }
  }

  /// Ajoute une nouvelle note
  Future<bool> addGradeEntry(GradeEntry gradeEntry) async {
    try {
      await _firestore
          .collection('notes')
          .doc(gradeEntry.id)
          .set(gradeEntry.toFirestore());

      _gradeEntries.add(gradeEntry);
      _gradeEntries.sort((a, b) => b.date.compareTo(a.date));

      if (_selectedClass != null) {
        await loadClassStatistics(_selectedClass!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur addGradeEntry: $e');
      return false;
    }
  }

  /// Met à jour une note
  Future<bool> updateGradeEntry(GradeEntry gradeEntry) async {
    try {
      await _firestore
          .collection('notes')
          .doc(gradeEntry.id)
          .update(gradeEntry.toFirestore());

      final index = _gradeEntries.indexWhere((g) => g.id == gradeEntry.id);
      if (index != -1) {
        _gradeEntries[index] = gradeEntry;
      }

      if (_selectedClass != null) {
        await loadClassStatistics(_selectedClass!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur updateGradeEntry: $e');
      return false;
    }
  }

  /// Supprime une note
  Future<bool> deleteGradeEntry(String gradeId) async {
    try {
      await _firestore.collection('notes').doc(gradeId).delete();

      _gradeEntries.removeWhere((g) => g.id == gradeId);

      if (_selectedClass != null) {
        await loadClassStatistics(_selectedClass!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur deleteGradeEntry: $e');
      return false;
    }
  }

  // ================== DEVOIRS (ASSIGNMENTS) ==================

  /// Attribue un devoir à une classe (création dans la collection `devoirs`).
  /// Le rendu de chaque élève est géré séparément dans `rendus_devoirs`.
  Future<bool> addHomework({
    required String classe,
    required String matiere,
    required String titre,
    required String description,
    required DateTime dateLimite,
    Map<String, dynamic>? fichier,
  }) async {
    try {
      final trimmedClasse = classe.trim();
      final trimmedMatiere = matiere.trim();
      final trimmedTitre = titre.trim();
      final trimmedDescription = description.trim();

      await _firestore.collection('devoirs').add({
        'classe': trimmedClasse,
        'matiere': trimmedMatiere,
        'titre': trimmedTitre,
        'description': trimmedDescription,
        'dateLimite': Timestamp.fromDate(dateLimite),
        'estRendu': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        if (fichier != null) 'fichier': fichier,
      });

      return true;
    } catch (e) {
      debugPrint('❌ Erreur addHomework: $e');
      return false;
    }
  }

  /// Retourne toutes les notes d'une matière
  List<GradeEntry> getSubjectGrades(String matiere) {
    return _gradeEntries.where((g) => g.matiere == matiere).toList();
  }

  /// Retourne les notes d'un élève pour une matière
  List<GradeEntry> getStudentSubjectGrades(String studentId, String matiere) {
    return _gradeEntries
        .where((g) => g.eleveId == studentId && g.matiere == matiere)
        .toList();
  }

  /// Retourne la moyenne pondérée d'un élève pour une matière
  double getStudentSubjectAverage(String studentId, String matiere) {
    final grades = getStudentSubjectGrades(studentId, matiere);
    if (grades.isEmpty) return 0;

    double totalWeightedScore = 0;
    double totalCoefficient = 0;

    for (var grade in grades) {
      totalWeightedScore += grade.note * grade.coefficient;
      totalCoefficient += grade.coefficient;
    }

    return totalCoefficient > 0 ? totalWeightedScore / totalCoefficient : 0;
  }

  /// Met à jour le profil du professeur
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? phone,
    String? photoPath,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) {
        _firstName = firstName;
        updates['prenom'] = firstName;
      }
      if (lastName != null) {
        _lastName = lastName;
        updates['nom'] = lastName;
      }
      if (displayName != null) {
        _displayName = displayName;
        updates['displayName'] = displayName;
      }
      if (phone != null) {
        _phone = phone;
        updates['phone'] = phone;
      }
      if (photoPath != null) {
        _photoPath = photoPath;
        updates['photoPath'] = photoPath;
      }

      await _firestore.collection('utilisateurs').doc(uid).update(updates);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur updateProfile: $e');
      return false;
    }
  }

  /// Nettoie les données (à l'app dispose)
  void dispose() {
    _gradeEntries.clear();
    _classStatisticsMap.clear();
    super.dispose();
  }
}
