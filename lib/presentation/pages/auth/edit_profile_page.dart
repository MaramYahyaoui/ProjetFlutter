import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/services/firebase_service.dart';
import '../../widgets/user_profile_image_picker.dart';

/// Page pour modifier le profil utilisateur
/// Inclut upload de photo
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late AuthController _authController;
  late FirebaseService _firebaseService;
  late TextEditingController _displayNameController;
  late String? _photoDataUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _authController = context.read<AuthController>();
    _firebaseService = FirebaseService();
    _displayNameController = TextEditingController(
      text: _authController.user?.displayName ?? '',
    );
    _photoDataUrl = _authController.user?.photoPath;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      _showError('Veuillez entrer un non');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _authController.user;
      if (user == null) throw Exception('Utilisateur non trouvé');

      final updatedUser = user.copyWith(
        displayName: _displayNameController.text.trim(),
        photoPath: _photoDataUrl,
      );

      // Sauvegarder dans Firestore
      await _firebaseService.setUserProfile(user.id, updatedUser);

      // Mettre à jour l'AuthController
      _authController.setUser(updatedUser);

      if (mounted) {
        _showSuccess('Profil mis à jour avec succès');
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ========== PHOTO PICKER ==========
            UserProfileImagePicker(
              initialPhotoDataUrl: _photoDataUrl,
              onImagePicked: (dataUrl) {
                setState(() => _photoDataUrl = dataUrl);
              },
              size: 120,
            ),

            const SizedBox(height: 30),

            // ========== NOM AFFICHAGE ==========
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Nom affiché',
                hintText: 'Votre nom',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Firestore
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                '⚠️ La photo sera stockée en base64 dans Firestore.\n'
                'Taille limite: 5MB',
                style: TextStyle(fontSize: 12),
              ),
            ),

            const SizedBox(height: 30),

            // ========== BOUTON SAUVEGARDER ==========
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F5EDB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sauvegarder',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
