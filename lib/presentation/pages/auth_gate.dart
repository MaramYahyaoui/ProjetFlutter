import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/student_controller.dart';
import '../../models/user_model.dart';
import '../pages/auth/Login.dart';
import '../pages/student/screens/student_dashboard.dart';
import '../pages/teacher/teacher_dashboard.dart';
import '../pages/parent/parent_dashboard.dart';
import '../pages/admin/admin_shell.dart';

/// Auth Gate - Route protection
/// Vérifie l'état d'authentification et affiche le bon écran
/// - Non authentifié → LoginPage
/// - Authentifié → Dashboard selon le rôle
/// - En cours de chargement → SplashScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // En cours de chargement initial
        if (authController.isLoading && authController.user == null) {
          return const SplashScreen();
        }

        // Non authentifié → LoginPage
        if (!authController.isAuthenticated || authController.user == null) {
          return const LoginPage();
        }

        // Authentifié → Dashboard selon le rôle
        return _buildDashboard(authController.user!);
      },
    );
  }

  /// Construit le dashboard selon le rôle de l'utilisateur
  /// Fournit les bons providers selon le contexte
  Widget _buildDashboard(User user) {
    switch (user.role) {
      case 'eleve':
        // Fournit StudentController pour le StudentDashboard
        return ChangeNotifierProvider(
          create: (_) => StudentController(user.id),
          child: const StudentDashboard(),
        );
      case 'enseignant':
        return const TeacherDashboard();
      case 'parent':
        return const ParentDashboard();
      case 'admin':
        return const AdminShell();
      default:
        return ChangeNotifierProvider(
          create: (_) => StudentController(user.id),
          child: const StudentDashboard(),
        );
    }
  }
}

/// Écran de splash affiché pendant le chargement initial
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F5EDB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.school,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),

            // App name
            const Text(
              'EduLycée',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Votre espace scolaire numérique',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
