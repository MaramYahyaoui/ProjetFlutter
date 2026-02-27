import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String subject;
  final String teacher;
  final String classroom;
  final String day;
  final String startTime;
  final String endTime;
  final String? color;

  Schedule({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.classroom,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.color,
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Schedule(
      id: doc.id,
      subject: data['subject'],
      teacher: data['teacher'],
      classroom: data['classroom'],
      day: data['day'],
      startTime: data['startTime'],
      endTime: data['endTime'],
      color: data['color'],
    );
  }
}
