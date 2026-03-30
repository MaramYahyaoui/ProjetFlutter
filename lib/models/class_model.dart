import 'package:equatable/equatable.dart';

class TeacherClass extends Equatable {
  final String id;
  final String name; // ex: "2nde A", "2nde B"
  final String level; // ex: "Seconde", "Première"
  final String subject; // ex: "Mathématiques"
  final int studentCount;
  final List<String> studentIds; // IDs des élèves
  final DateTime createdAt;
  final bool isActive;

  const TeacherClass({
    required this.id,
    required this.name,
    required this.level,
    required this.subject,
    required this.studentCount,
    this.studentIds = const [],
    required this.createdAt,
    this.isActive = true,
  });

  /// Convertit depuis un document Firestore
  factory TeacherClass.fromFirestore(Map<String, dynamic> data, String id) {
    return TeacherClass(
      id: id,
      name: (data['name'] as String?) ?? '',
      level: (data['level'] as String?) ?? '',
      subject: (data['subject'] as String?) ?? '',
      studentCount: (data['studentCount'] as int?) ?? 0,
      studentIds: List<String>.from((data['studentIds'] as List?) ?? []),
      createdAt: (data['createdAt'] as DateTime?) ?? DateTime.now(),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  /// Convertit vers un document Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'level': level,
      'subject': subject,
      'studentCount': studentCount,
      'studentIds': studentIds,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  TeacherClass copyWith({
    String? id,
    String? name,
    String? level,
    String? subject,
    int? studentCount,
    List<String>? studentIds,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return TeacherClass(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      subject: subject ?? this.subject,
      studentCount: studentCount ?? this.studentCount,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    level,
    subject,
    studentCount,
    studentIds,
    createdAt,
    isActive,
  ];
}
