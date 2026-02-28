import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  final String id;
  final String classe;
  final String matiere;
  final String titre;
  final String description;
  final Timestamp dateLimite;
  final bool estRendu;

  Homework({
    required this.id,
    required this.classe,
    required this.matiere,
    required this.titre,
    required this.description,
    required this.dateLimite,
    required this.estRendu,
  });

  factory Homework.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Homework(
      id: doc.id,
      classe: data['classe'] ?? '',
      matiere: data['matiere'] ?? '',
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      dateLimite: data['dateLimite'] ?? Timestamp.now(),
      estRendu: data['estRendu'] ?? false,
    );
  }

  // Getters for backward compatibility (optional)
  String get subject => matiere;
  String get title => titre;
  Timestamp get dueDate => dateLimite;
  bool get isCompleted => estRendu;
}
