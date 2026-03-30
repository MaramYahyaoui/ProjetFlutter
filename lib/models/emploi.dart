import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String subject;      // matiere
  final String? teacher;     // professeur (optional)
  final String classroom;    // salle
  final int dayOfWeek;       // jour_semaine (1=Lundi, 7=Dimanche)
  final String startTime;    // debut
  final String endTime;      // fin
  final String type;         // "professeur" or "eleve"
  final String? ownerId;     // user ID reference
  final String? color;       // hex color for UI

  Schedule({
    required this.id,
    required this.subject,
    this.teacher,
    required this.classroom,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.ownerId,
    this.color,
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Schedule(
      id: doc.id,
      subject: data['matiere'] ?? '',
      teacher: data['professeur'],
      classroom: data['salle'] ?? '',
      dayOfWeek: data['jour_semaine'] ?? data['jour_semain'] ?? 1,
      startTime: data['debut'] ?? '08:00',
      endTime: data['fin'] ?? '10:00',
      type: data['type'] ?? 'eleve',
      ownerId: data['ownerId'] ?? data['eleveId'] ?? data['professeurId'] ?? '',
      color: data['color'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matiere': subject,
      'professeur': teacher,
      'salle': classroom,
      'jour_semaine': dayOfWeek,
      'debut': startTime,
      'fin': endTime,
      'type': type,
      'ownerId': ownerId,
      'color': color,
    };
  }

  // Helper to get day name
  String get dayName {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[dayOfWeek];
  }
}