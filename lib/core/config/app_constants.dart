/// Collections Firestore constants
class FirebaseCollections {
  static const String users = 'utilisateurs';
  static const String notes = 'notes';
  static const String homeworks = 'devoirs';
  static const String schedules = 'emplois';
  static const String conversations = 'conversations';
  static const String messages = 'messages';

  // Alias pour compatibilité
  static const String utilisateurs = users;
  static const String devoirs = homeworks;
  static const String emplois = schedules;
}

/// User roles 
class UserRoles {
  static const String student = 'eleve';
  static const String teacher = 'enseignant';
  static const String parent = 'parent';
  static const String admin = 'admin';

  /// Liste de tous les rôles disponibles
  static const List<String> all = [student, teacher, parent, admin];

  /// Obtient le label d'affichage pour un rôle
  static String getLabel(String role) {
    switch (role) {
      case student:
        return 'Élève';
      case teacher:
        return 'Professeur';
      case parent:
        return 'Parent';
      case admin:
        return 'Administrateur';
      default:
        return role;
    }
  }
}

/// Firebase field names constants
class FirebaseFields {
  // User fields
  static const String email = 'email';
  static const String firstName = 'prenom';
  static const String lastName = 'nom';
  static const String displayName = 'displayName';
  static const String role = 'role';
  static const String classe = 'classe';
  static const String createdAt = 'createdAt';
  static const String isEmailVerified = 'isEmailVerified';
  static const String isActive = 'isActive';

  // Notes fields
  static const String studentId = 'eleveId';
  static const String subject = 'matiere';
  static const String grade = 'note';
  static const String maxGrade = 'noteMax';
  static const String date = 'date';

  // Homeworks fields
  static const String title = 'titre';
  static const String description = 'description';
  static const String dueDate = 'dateLimite';
  static const String isCompleted = 'estRendu';

  // Schedule fields
  static const String startTime = 'heureDebut';
  static const String endTime = 'heureFin';
  static const String dayOfWeek = 'jour';
  static const String location = 'salle';

  // Messaging fields
  static const String participants = 'participants';
  static const String participantNames = 'participantNames';
  static const String unreadCounts = 'unreadCounts';
  static const String lastMessage = 'lastMessage';
  static const String lastSenderId = 'lastSenderId';
  static const String lastMessageAt = 'lastMessageAt';
  static const String updatedAt = 'updatedAt';
  static const String text = 'text';
  static const String senderId = 'senderId';
  static const String senderName = 'senderName';
}

/// App constants
class AppConstants {
  static const String appName = 'EduLycée';
  static const String appVersion = '1.0.0';

  // Authentication errors
  static const String errorUserNotFound = 'user-not-found';
  static const String errorWrongPassword = 'wrong-password';
  static const String errorInvalidEmail = 'invalid-email';
  static const String errorUserDisabled = 'user-disabled';
  static const String errorTooManyRequests = 'too-many-requests';
  static const String errorInvalidCredential = 'invalid-credential';
}
