import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String role; // eleve, enseignant, parent, admin
  final String? classe;
  final String? photoPath; // Data URL de la photo de profil
  final DateTime? createdAt;
  final bool isEmailVerified;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    required this.role,
    this.classe,
    this.photoPath,
    this.createdAt,
    this.isEmailVerified = false,
    this.isActive = true,
  });

  /// Obtient le nom complet de l'utilisateur
  String get fullName {
    final dn = (displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    final full = [fn, ln].where((p) => p.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    return email;
  }

  /// Convertit depuis un document Firestore
  factory User.fromFirestore(Map<String, dynamic> data, String uid) {
    return User(
      id: uid,
      email: data['email'] as String? ?? '',
      firstName: (data['prenom'] as String?)?.trim(),
      lastName: (data['nom'] as String?)?.trim(),
      displayName: (data['displayName'] as String?)?.trim() ??
          (data['name'] as String?)?.trim(),
      role: data['role'] as String? ?? 'eleve',
      classe: (data['classe'] ?? data['class'])?.toString().trim(),
      photoPath: (data['photoPath'] as String?)?.trim(),
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convertit vers un objet JSON pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'prenom': firstName,
      'nom': lastName,
      'displayName': displayName,
      'role': role,
      'classe': classe,
      'photoPath': photoPath,
      'createdAt': createdAt,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
    };
  }

  /// Crée une copie avec certains champs modifiés
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? displayName,
    String? role,
    String? classe,
    String? photoPath,
    DateTime? createdAt,
    bool? isEmailVerified,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      classe: classe ?? this.classe,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        displayName,
        role,
        classe,
        photoPath,
        createdAt,
        isEmailVerified,
        isActive,
      ];
}
