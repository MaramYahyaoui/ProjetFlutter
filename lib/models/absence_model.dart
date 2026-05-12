import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Absence extends Equatable {
  final String id;
  final String studentId;      // ID de l'élève absent
  final String? scheduleId;    // ID du cours concerné
  final String subject;        // Matière/Cours
  final DateTime date;         // Date de l'absence
  final String startTime;      // Heure début (format HH:mm)
  final String endTime;        // Heure fin (format HH:mm)
  final String status;         // absent, justified, late
  final String? reason;        // Raison si justifiée
  final String? reportedBy;    // ID du professeur qui a saisi
  final DateTime? justifiedAt; // Date de justification
  final String? document;      // URL du justificatif (si besoin futur)
  final DateTime createdAt;    // Date de création

  const Absence({
    required this.id,
    required this.studentId,
    this.scheduleId,
    required this.subject,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'absent',
    this.reason,
    this.reportedBy,
    this.justifiedAt,
    this.document,
    required this.createdAt,
  });

  /// Vérifier si l'absence est justifiée
  bool get isJustified => status == 'justified';

  /// Vérifier si c'est un retard
  bool get isLate => status == 'late';

  /// Convertit depuis un document Firestore
  factory Absence.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Absence(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      scheduleId: data['scheduleId'] as String?,
      subject: data['subject'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] as String? ?? '08:00',
      endTime: data['endTime'] as String? ?? '10:00',
      status: data['status'] as String? ?? 'absent',
      reason: data['reason'] as String?,
      reportedBy: data['reportedBy'] as String?,
      justifiedAt: (data['justifiedAt'] as Timestamp?)?.toDate(),
      document: data['document'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertit vers un format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'scheduleId': scheduleId,
      'subject': subject,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'reason': reason,
      'reportedBy': reportedBy,
      'justifiedAt': justifiedAt != null ? Timestamp.fromDate(justifiedAt!) : null,
      'document': document,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Créer une copie avec des modifications
  Absence copyWith({
    String? id,
    String? studentId,
    String? scheduleId,
    String? subject,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? status,
    String? reason,
    String? reportedBy,
    DateTime? justifiedAt,
    String? document,
    DateTime? createdAt,
  }) {
    return Absence(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      scheduleId: scheduleId ?? this.scheduleId,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      reportedBy: reportedBy ?? this.reportedBy,
      justifiedAt: justifiedAt ?? this.justifiedAt,
      document: document ?? this.document,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    scheduleId,
    subject,
    date,
    startTime,
    endTime,
    status,
    reason,
    reportedBy,
    justifiedAt,
    document,
    createdAt,
  ];
}
