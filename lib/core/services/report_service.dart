import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore;

  ReportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Compute a report for optional filters. If [from] or [to] are null,
  /// the method will compute over all available notes.
  Future<ReportModel> computeReport({
    String? classe,
    String? eleveId,
    DateTime? from,
    DateTime? to,
  }) async {
    // Load users
    final usersSnap = await _firestore.collection('utilisateurs').get();
    final users = usersSnap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList(growable: false);

    final students = users
        .where((u) {
          final role = ((u['role'] ?? u['type']) ?? '')
              .toString()
              .toLowerCase();
          return role.contains('eleve') || role.contains('student');
        })
        .toList(growable: false);
    final teachers = users
        .where((u) {
          final role = ((u['role'] ?? u['type']) ?? '')
              .toString()
              .toLowerCase();
          return role.contains('enseignant') || role.contains('teacher');
        })
        .toList(growable: false);
    final parents = users
        .where((u) {
          final role = ((u['role'] ?? u['type']) ?? '')
              .toString()
              .toLowerCase();
          return role.contains('parent') || role.contains('tuteur');
        })
        .toList(growable: false);

    // Build notes query
    Query<Map<String, dynamic>> q = _firestore.collection('notes');
    if (eleveId != null && eleveId.isNotEmpty) {
      q = q.where('eleveId', isEqualTo: eleveId);
    }
    if (from != null) {
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }

    final notesSnap = await q.get();
    final notes = notesSnap.docs.map((d) => d.data()).toList(growable: false);

    // Apply class filter if provided (requires mapping eleveId->classe)
    Map<String, String> classByStudent = {};
    for (final s in students) {
      final id = s['id']?.toString() ?? '';
      final cls = (s['classe'] ?? s['class'] ?? '')?.toString() ?? '';
      if (id.isNotEmpty) classByStudent[id] = cls;
    }

    final filteredNotes = classe == null || classe.isEmpty
        ? notes
        : notes
              .where((n) {
                final eid = (n['eleveId'] ?? '').toString();
                final c = classByStudent[eid] ?? '';
                return c.trim().toLowerCase() == classe.trim().toLowerCase();
              })
              .toList(growable: false);

    final noteValues = filteredNotes
        .map((n) => (n['note'] as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);
    final notesCount = noteValues.length;
    final avg = notesCount == 0
        ? 0.0
        : noteValues.reduce((a, b) => a + b) / notesCount;
    final successRate = notesCount == 0
        ? 0.0
        : (noteValues.where((v) => v >= 10).length / notesCount) * 100;

    // Activity: default to last 7 days if from/to not provided
    DateTime start, end;
    if (from != null && to != null) {
      start = DateTime(from.year, from.month, from.day);
      end = DateTime(to.year, to.month, to.day);
    } else {
      end = DateTime.now();
      start = DateTime(
        end.year,
        end.month,
        end.day,
      ).subtract(const Duration(days: 6));
    }
    final days = end.difference(start).inDays + 1;
    final activityLabels = List<String>.generate(days, (i) {
      final d = start.add(Duration(days: i));
      return '${d.day}/${d.month}';
    }, growable: false);
    final activityValues = List<double>.filled(days, 0.0, growable: false);
    for (final n in filteredNotes) {
      final dRaw = n['date'];
      if (dRaw is Timestamp) {
        final dt = dRaw.toDate();
        if (!dt.isBefore(start) && !dt.isAfter(end)) {
          final idx = dt.difference(start).inDays;
          if (idx >= 0 && idx < days) activityValues[idx] += 1.0;
        }
      }
    }

    // Top classes (count of notes per class)
    final Map<String, int> classesCountMap = {};
    for (final n in filteredNotes) {
      final eid = (n['eleveId'] ?? '').toString();
      final c = classByStudent[eid] ?? '';
      if (c.trim().isEmpty) continue;
      classesCountMap.update(c.trim(), (v) => v + 1, ifAbsent: () => 1);
    }
    final classEntries = classesCountMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topClasses = classEntries.take(5).toList(growable: false);
    final classLabels = topClasses.map((e) => e.key).toList(growable: false);
    final classValues = topClasses
        .map((e) => e.value.toDouble())
        .toList(growable: false);

    // Avg by subject
    final Map<String, List<double>> bySubject = {};
    for (final n in filteredNotes) {
      final subj = (n['matiere'] ?? '').toString();
      final v = (n['note'] as num?)?.toDouble() ?? 0.0;
      if (subj.isEmpty) continue;
      bySubject.putIfAbsent(subj, () => []).add(v);
    }
    final Map<String, double> averageBySubject = {};
    bySubject.forEach((k, list) {
      averageBySubject[k] = list.reduce((a, b) => a + b) / list.length;
    });

    return ReportModel(
      studentsCount: students.length,
      teachersCount: teachers.length,
      parentsCount: parents.length,
      classesCount: classByStudent.values.toSet().length,
      average: avg,
      successRate: successRate,
      notesCount: notesCount,
      activityLabels: activityLabels,
      activityValues: activityValues,
      classLabels: classLabels,
      classValues: classValues,
      averageBySubject: averageBySubject,
    );
  }
}
