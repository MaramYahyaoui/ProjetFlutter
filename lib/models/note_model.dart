import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String matiere;
  final double note;
  final double coefficient;
  final DateTime date;
  final String type;
  final String? comment;

  Note({
    required this.id,
    required this.matiere,
    required this.note,
    required this.coefficient,
    required this.date,
    required this.type,
    this.comment,
  });

  double get percentage => (note / 20) * 100;

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Note(
      id: doc.id,
      matiere: data['matiere'] ?? '',
      note: (data['note'] ?? 0).toDouble(),
      coefficient: (data['coefficient'] ?? 1).toDouble(),
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      type: data['type'] ?? '',
      comment: data['comment'],
    );
  }
}
