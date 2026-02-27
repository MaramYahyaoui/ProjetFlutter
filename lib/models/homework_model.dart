import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  final String id;
  final String subject;
  final String title;
  final String description;
  final Timestamp dueDate;
  final bool isCompleted;

  Homework({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
  });

  factory Homework.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Homework(
      id: doc.id,
      subject: data['subject'],
      title: data['title'],
      description: data['description'],
      dueDate: data['dueDate'],
      isCompleted: data['isCompleted'],
    );
  }
}
