import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devmob_edulycee/presentation/pages/auth/widgets/role_selector.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import tes pages (à créer)
import '../student/screens/student_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool obscurePassword = true;
  String? selectedRole;
  bool isLoading = false;

  Future<void> login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showError("Veuillez remplir tous les champs");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Login avec Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user == null) {
        showError("Utilisateur non trouvé");
        return;
      }

      // 2. Récupérer le rôle depuis Firestore (collection "utilisateurs")
      final userDoc = await _firestore
          .collection('utilisateurs')  // ← "utilisateurs" pas "users"
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        showError("Profil utilisateur non trouvé dans Firestore");
        return;
      }

      final userData = userDoc.data()!;
      final String role = userData['role'] ?? 'eleve';  // ← "eleve" pas "student"

      // 3. Vérifier si le rôle sélectionné correspond (optionnel)
      if (selectedRole != null && selectedRole != role) {
        showError("Ce compte n'a pas le rôle sélectionné");
        setState(() => isLoading = false);
        return;
      }

      // 4. Rediriger selon le rôle
      navigateToDashboard(role);

    } on FirebaseAuthException catch (e) {
      String message = "Erreur de connexion";
      
      // Gestion détaillée des erreurs Firebase Auth
      switch (e.code) {
        case 'user-not-found':
          message = "Aucun compte trouvé avec cet email";
          break;
        case 'wrong-password':
          message = "Mot de passe incorrect";
          break;
        case 'invalid-email':
          message = "Format d'email invalide";
          break;
        case 'user-disabled':
          message = "Ce compte a été désactivé";
          break;
        case 'too-many-requests':
          message = "Trop de tentatives. Réessayez plus tard";
          break;
        case 'invalid-credential':
          message = "Email ou mot de passe incorrect";
          break;
        case 'INVALID_LOGIN_CREDENTIALS':
          message = "Email ou mot de passe incorrect";
          break;
        default:
          message = "Erreur de connexion: ${e.code}";
          print("Firebase Auth Error: ${e.code} - ${e.message}");
      }
      
      showError(message);
    } catch (e) {
      print("Erreur générale: $e");
      showError("Erreur: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void navigateToDashboard(String role) {
    Widget dashboard;
    
    switch (role) {
      case 'eleve':
        dashboard = const StudentDashboard();
        break;
      case 'enseignant':  // Corrigé: "enseignant" au lieu de "professeur"
        dashboard = const TeacherDashboard();
        break;
      case 'parent':
        dashboard = const ParentDashboard();
        break;
      case 'admin':
        dashboard = const AdminDashboard();
        break;
      default:
        dashboard = const StudentDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER (ton code existant)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F5EDB), Color(0xFF1C3FAA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: const [
                  Icon(Icons.school, size: 60, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "EduLycee",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Votre espace scolaire numérique",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // CARD LOGIN
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Connexion",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "votre@email.fr",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: "********",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Mot de passe oublié ?"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // BOUTON LOGIN
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F5EDB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Se connecter",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Center(
                        child: Text(
                          "OU CHOISIR UN PROFIL",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ROLE SELECTOR
                      RoleSelector(
                        selectedRole: selectedRole,
                        onSelect: (role) {
                          setState(() {
                            selectedRole = role;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}