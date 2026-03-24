import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../../firebase_options.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'eleve';
  String? _selectedClass;
  late final Future<List<String>> _classesFuture;
  bool _loading = false;
  bool _obscure = true;

  String? _validateStrongPassword({
    required String password,
    required String email,
    required String firstName,
    required String lastName,
  }) {
    if (password.isEmpty) return 'Champ requis';

    // Avoid surprises with passwords copied with spaces/newlines.
    if (RegExp(r'\s').hasMatch(password)) {
      return "Le mot de passe ne doit pas contenir d'espaces";
    }

    if (password.length < 12) {
      return 'Min 12 caractères';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Ajoutez au moins une minuscule';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Ajoutez au moins une majuscule';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Ajoutez au moins un chiffre';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Ajoutez au moins un caractère spécial';
    }

    final lowered = password.toLowerCase();

    // Very common/weak passwords denylist (small on purpose).
    const banned = <String>{
      'password',
      'motdepasse',
      'azerty',
      'qwerty',
      'admin',
      '123456',
      '123456789',
      '000000',
      '111111',
      'abcdef',
    };
    if (banned.contains(lowered)) {
      return 'Mot de passe trop courant';
    }

    // Reject trivial repetition like aaaaaaaaaaaa
    if (RegExp(r'^(.)\1{7,}$').hasMatch(password)) {
      return 'Évitez les caractères répétés';
    }

    // Avoid passwords derived from identity info.
    final emailValue = email.trim().toLowerCase();
    final localPart = emailValue.contains('@')
        ? emailValue.split('@').first
        : emailValue;
    if (localPart.length >= 3 && lowered.contains(localPart)) {
      return "N'utilisez pas votre email dans le mot de passe";
    }

    final fn = firstName.trim().toLowerCase();
    if (fn.length >= 3 && lowered.contains(fn)) {
      return "N'utilisez pas votre prénom dans le mot de passe";
    }

    final ln = lastName.trim().toLowerCase();
    if (ln.length >= 3 && lowered.contains(ln)) {
      return "N'utilisez pas votre nom dans le mot de passe";
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _classesFuture = _loadClasses();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final secondary = await _getOrCreateSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);

      final created = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = created.user?.uid;
      if (uid == null) {
        throw Exception("Impossible de créer l'utilisateur");
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final displayName = [
        lastName,
        firstName,
      ].where((p) => p.isNotEmpty).join(' ');

      await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).set({
        'uid': uid,
        'email': email,
        'role': _role,
        'prenom': firstName,
        'nom': lastName,
        'displayName': displayName,
        'classe': (_selectedClass ?? '').trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => "Cet email est déjà utilisé",
        'invalid-email' => "Email invalide",
        'weak-password' =>
          "Mot de passe trop faible (12+ caractères, maj/min/chiffre/spécial)",
        _ => "Erreur: ${e.code}",
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    for (final app in Firebase.apps) {
      if (app.name == 'Secondary') return app;
    }

    return Firebase.initializeApp(
      name: 'Secondary',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<List<String>> _loadClasses() async {
    final firestore = FirebaseFirestore.instance;
    final classNames = <String>{};

    try {
      final snap = await firestore.collection('classes').orderBy('name').get();
      for (final d in snap.docs) {
        final data = d.data();
        final name = ((data['name'] ?? d.id) ?? '').toString().trim();
        if (name.isNotEmpty) classNames.add(name);
      }
    } catch (_) {
      // ignore - fallback below
    }

    // Fallback for existing data where classes are only present on user docs.
    if (classNames.isEmpty) {
      final usersSnap = await firestore
          .collection('utilisateurs')
          .limit(500)
          .get();
      for (final d in usersSnap.docs) {
        final data = d.data();
        final name = ((data['classe'] ?? data['class']) ?? '')
            .toString()
            .trim();
        if (name.isNotEmpty) classNames.add(name);
      }
    }

    final list = classNames.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajouter un utilisateur',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(
                label: 'Nom',
                child: TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Dubois'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Prénom',
                child: TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Marie'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Email',
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('marie.dubois@edulycee.fr'),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Champ requis';
                    if (!value.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Mot de passe initial',
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    return _validateStrongPassword(
                      password: (v ?? ''),
                      email: _emailController.text,
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Rôle',
                child: DropdownButtonFormField<String>(
                  value: _role,
                  decoration: _inputDecoration(''),
                  items: const [
                    DropdownMenuItem(value: 'eleve', child: Text('Élève')),
                    DropdownMenuItem(
                      value: 'enseignant',
                      child: Text('Professeur'),
                    ),
                    DropdownMenuItem(value: 'parent', child: Text('Parent')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'eleve'),
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: _role == 'eleve' ? 'Classe' : 'Classe (optionnel)',
                child: FutureBuilder<List<String>>(
                  future: _classesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final classes = snapshot.data ?? const <String>[];

                    return DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: _inputDecoration(''),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-'),
                        ),
                        ...classes.map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedClass = v),
                      validator: (v) {
                        if (_role != 'eleve') return null;
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Champ requis';
                        return null;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Créer',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
