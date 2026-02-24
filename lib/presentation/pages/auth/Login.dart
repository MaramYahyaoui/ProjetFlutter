import 'package:devmob_edulycee/presentation/pages/auth/widgets/role_selector.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool obscurePassword = true;
  String? selectedRole;

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // TODO: récupérer le rôle depuis Firestore
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
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

                      TextButton(
                        onPressed: () {},
                        child: const Text("Mot de passe oublié ?"),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Se connecter",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Center(child: Text("OU CHOISIR UN PROFIL")),
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

  Widget roleItem(String role, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: selectedRole == role
                ? Colors.blue
                : Colors.grey[300],
            child: Icon(
              icon,
              color: selectedRole == role ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(role),
        ],
      ),
    );
  }
}
