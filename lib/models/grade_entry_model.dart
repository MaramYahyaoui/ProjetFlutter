import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GradeEntry extends Equatable {
  final String id;
  final String profId; // ID du professeur
  final String eleveId; // ID de l'élève
  final String matiere;
  final String type; // "exam", "contrôle", "devoir", etc.
  final double note; // 0-20
  final double coefficient;
  final DateTime date;
  final String? commentaire;

  const GradeEntry({
    required this.id,
    required this.profId,
    required this.eleveId,
    required this.matiere,
    required this.type,
    required this.note,
    required this.coefficient,
    required this.date,
    this.commentaire,
  });

  /// Convertit depuis un document Firestore
  factory GradeEntry.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime dateValue = DateTime.now();

    // Handle Firestore Timestamp conversion
    final dateField = data['date'];
    if (dateField is Timestamp) {
      dateValue = dateField.toDate();
    } else if (dateField is DateTime) {
      dateValue = dateField;
    }

    return GradeEntry(
      id: id,
      profId: (data['profId'] as String?) ?? '',
      eleveId: (data['eleveId'] as String?) ?? '',
      matiere: (data['matiere'] as String?) ?? '',
      type: (data['type'] as String?) ?? '',
      note: ((data['note'] as num?) ?? 0).toDouble(),
      coefficient: ((data['coefficient'] as num?) ?? 1).toDouble(),
      date: dateValue,
      commentaire: (data['commentaire'] as String?),
    );
  }

  /// Convertit vers un document Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'profId': profId,
      'eleveId': eleveId,
      'matiere': matiere,
      'type': type,
      'note': note,
      'coefficient': coefficient,
      'date': date,
      'commentaire': commentaire,
    };
  }

  GradeEntry copyWith({
    String? id,
    String? profId,
    String? eleveId,
    String? matiere,
    String? type,
    double? note,
    double? coefficient,
    DateTime? date,
    String? commentaire,
  }) {
    return GradeEntry(
      id: id ?? this.id,
      profId: profId ?? this.profId,
      eleveId: eleveId ?? this.eleveId,
      matiere: matiere ?? this.matiere,
      type: type ?? this.type,
      note: note ?? this.note,
      coefficient: coefficient ?? this.coefficient,
      date: date ?? this.date,
      commentaire: commentaire ?? this.commentaire,
    );
  }

  @override
  List<Object?> get props => [
    id,
    profId,
    eleveId,
    matiere,
    type,
    note,
    coefficient,
    date,
    commentaire,
  ];
}

class GradeStatistics extends Equatable {
  final double average;
  final double median; // Note médiane
  final double successRate; // 0-100
  final int evaluationCount;
  final int studentCount;
  final double minScore;
  final double maxScore;
  final Map<String, int>
  scoreDistribution; // Répartition par plage: {"0-5": 2, "5-10": 4, ...}
  final List<double> allScores; // Toutes les notes pour calculs futurs

  const GradeStatistics({
    required this.average,
    required this.median,
    required this.successRate,
    required this.evaluationCount,
    required this.studentCount,
    required this.minScore,
    required this.maxScore,
    this.scoreDistribution = const {},
    this.allScores = const [],
  });

  @override
  List<Object?> get props => [
    average,
    median,
    successRate,
    evaluationCount,
    studentCount,
    minScore,
    maxScore,
    scoreDistribution,
    allScores,
  ];
}
