import 'package:devmob_edulycee/models/emploi.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';
import '../models/homework_model.dart';
import '../models/emploi.dart';

class StudentController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;


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
      loadNotes(),
      loadHomeworks(),
      loadSchedules(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNotes() async {
    final snapshot = await _firestore
        .collection('notes')
        .where('eleveId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .get();

    _notes =
        snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
  }

  Future<void> loadHomeworks() async {
    final snapshot = await _firestore
        .collection('homeworks')
        .where('eleveId', isEqualTo: _uid)
        .orderBy('dueDate')
        .get();

    _homeworks = snapshot.docs
        .map((doc) => Homework.fromFirestore(doc))
        .toList();
  }

  Future<void> loadSchedules() async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('eleveId', isEqualTo: _uid)
        .get();

    final Map<String, List<Schedule>> grouped = {};

    for (var doc in snapshot.docs) {
      final schedule = Schedule.fromFirestore(doc);
      grouped.putIfAbsent(schedule.day, () => []);
      grouped[schedule.day]!.add(schedule);
    }

    _schedules = grouped;
  }

  double getAverage() {
    if (_notes.isEmpty) return 0;
    final sum =
        _notes.fold<double>(0, (sum, n) => sum + n.percentage);
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

      await _firestore
          .collection('homeworks')
          .doc(id)
          .update({'isCompleted': newValue});

      _homeworks[index] = Homework(
        id: _homeworks[index].id,
        subject: _homeworks[index].subject,
        title: _homeworks[index].title,
        description: _homeworks[index].description,
        dueDate: _homeworks[index].dueDate,
        isCompleted: newValue,
      );

      notifyListeners();
    }
  }
}
