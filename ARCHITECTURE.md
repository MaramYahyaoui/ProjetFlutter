# Architecture MVC - EduLycée

Ce projet suit le pattern **MVC (Model-View-Controller)** pour Flutter.

## 📁 Structure du projet

```
lib/
├── models/                  # MODEL - Modèles de données
│   ├── note_model.dart
│   ├── homework_model.dart
│   └── emploi.dart
│
├── controllers/             # CONTROLLER - Logique métier
│   └── student_controller.dart
│
├── presentation/            # VIEW - Interface utilisateur
│   └── pages/
│       ├── auth/
│       │   ├── Login.dart
│       │   └── widgets/
│       ├── student/
│       │   ├── screens/
│       │   │   ├── student_dashboard.dart
│       │   │   ├── notes_page.dart
│       │   │   ├── schedule_page.dart
│       │   │   └── homework_page.dart
│       │   └── widgets/
│       │       ├── note_card.dart
│       │       ├── schedule_card.dart
│       │       ├── stat_card.dart
│       │       └── section_header.dart
│       ├── teacher/
│       ├── parent/
│       └── admin/
│
└── main.dart                # Point d'entrée de l'application
```

## 🏗️ Composants de l'architecture MVC

### 1. **MODEL** (Modèles de données)
📂 Emplacement : `lib/models/`

Les modèles représentent la structure des données de l'application.

**Fichiers :**
- `note_model.dart` - Modèle pour les notes scolaires
- `homework_model.dart` - Modèle pour les devoirs
- `emploi.dart` - Modèle pour l'emploi du temps

**Responsabilités :**
- Définir la structure des données
- Méthodes de sérialisation (toJson/fromJson)
- Méthodes utilitaires (calculs, transformations)

**Exemple :**
```dart
class Note {
  final String id;
  final String subject;
  final double grade;
  final double maxGrade;
  
  double get percentage => (grade / maxGrade) * 100;
}
```

### 2. **VIEW** (Vues/Interface utilisateur)
📂 Emplacement : `lib/presentation/`

Les vues affichent les données et capturent les interactions utilisateur.

**Organisation :**
- `pages/` - Pages principales de l'application
- `screens/` - Écrans spécifiques à chaque rôle
- `widgets/` - Composants réutilisables

**Responsabilités :**
- Afficher l'interface utilisateur
- Capturer les événements utilisateur
- Communiquer avec le contrôleur
- Réagir aux changements de données

**Exemple :**
```dart
class StudentDashboard extends StatefulWidget {
  // Affiche le tableau de bord étudiant
  // Utilise StudentController pour les données
}
```

### 3. **CONTROLLER** (Contrôleurs)
📂 Emplacement : `lib/controllers/`

Les contrôleurs gèrent la logique métier et font le lien entre les modèles et les vues.

**Fichiers :**
- `student_controller.dart` - Gestion des données étudiants

**Responsabilités :**
- Gérer l'état de l'application
- Traiter la logique métier
- Manipuler les données (CRUD)
- Communiquer avec les APIs
- Notifier les vues des changements (via ChangeNotifier)

**Exemple :**
```dart
class StudentController extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> get notes => _notes;
  
  double getAverageGrade() {
    // Logique de calcul
  }
  
  void toggleHomeworkStatus(String id) {
    // Logique de mise à jour
    notifyListeners(); // Notifie les vues
  }
}
```

## 🔄 Flux de données

```
┌─────────┐         ┌────────────┐         ┌───────┐
│  VIEW   │ ◄─────► │ CONTROLLER │ ◄─────► │ MODEL │
└─────────┘         └────────────┘         └───────┘
    │                      │                    │
    │                      │                    │
 Affiche              Logique              Structure
 données              métier               données
    │                      │                    │
 Capture              Gère état            Validation
 événements           application          Sérialisation
```

### Exemple de flux :

1. **Utilisateur clique sur un devoir** (VIEW)
   ```dart
   onTap: () => controller.toggleHomeworkStatus(homework.id)
   ```

2. **Le contrôleur traite l'action** (CONTROLLER)
   ```dart
   void toggleHomeworkStatus(String id) {
     // Trouve le devoir
     // Met à jour son statut
     notifyListeners(); // Notifie les vues
   }
   ```

3. **La vue se met à jour automatiquement** (VIEW)
   ```dart
   Consumer<StudentController>(
     builder: (context, controller, child) {
       return ListView(
         children: controller.homeworks.map(...).toList(),
       );
     },
   )
   ```

## 📦 Gestion d'état

Le projet utilise **Provider** avec **ChangeNotifier** pour la gestion d'état :

```dart
// Dans main.dart
ChangeNotifierProvider(
  create: (_) => StudentController(),
  child: MyApp(),
)

// Dans les vues
final controller = Provider.of<StudentController>(context);
// ou
Consumer<StudentController>(
  builder: (context, controller, child) => ...
)
```

## 🎯 Avantages de cette architecture

1. **Séparation des responsabilités** - Chaque couche a un rôle clair
2. **Testabilité** - Les contrôleurs peuvent être testés indépendamment
3. **Maintenabilité** - Code organisé et facile à maintenir
4. **Réutilisabilité** - Les modèles et contrôleurs sont réutilisables
5. **Scalabilité** - Facile d'ajouter de nouvelles fonctionnalités

## 🚀 Prochaines étapes

Pour améliorer l'architecture :

1. **Ajouter des services** (`lib/services/`)
   - API service pour les appels réseau
   - Storage service pour la persistance locale
   - Auth service pour l'authentification

2. **Ajouter des repositories** (`lib/repositories/`)
   - Abstraire l'accès aux données
   - Gérer le cache et la synchronisation

3. **Améliorer la gestion d'état**
   - Utiliser Riverpod ou BLoC pour des cas complexes
   - Implémenter le state management réactif

4. **Tests**
   - Tests unitaires pour les modèles
   - Tests unitaires pour les contrôleurs
   - Tests de widgets pour les vues
