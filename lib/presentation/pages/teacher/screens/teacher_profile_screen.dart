import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/teacher_controller.dart';
import '../../../../controllers/auth_controller.dart';
import '../../notifications/notifications_page.dart';
import '../../settings/change_password_page.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../../widgets/user_profile_image_picker.dart';

enum _ProfileMenuAction { edit, changePassword, notifications, logout }

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late String? _photoDataUrl;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<TeacherController>();
    _firstNameController = TextEditingController(text: controller.firstName);
    _lastNameController = TextEditingController(text: controller.lastName);
    _phoneController = TextEditingController(text: controller.phone);
    _photoDataUrl = controller.photoPath.isNotEmpty
        ? controller.photoPath
        : null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        elevation: 0,
        actions: [
          const NotificationBellButton(
            iconColor: Colors.black87,
            iconSize: 24,
            dense: true,
          ),
          if (!_isEditingProfile)
            PopupMenuButton<_ProfileMenuAction>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => const [
                PopupMenuItem<_ProfileMenuAction>(
                  value: _ProfileMenuAction.edit,
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 12),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem<_ProfileMenuAction>(
                  value: _ProfileMenuAction.changePassword,
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: 12),
                      Text('Changer le mot de passe'),
                    ],
                  ),
                ),
                PopupMenuItem<_ProfileMenuAction>(
                  value: _ProfileMenuAction.notifications,
                  child: Row(
                    children: [
                      Icon(Icons.notifications_outlined),
                      SizedBox(width: 12),
                      Text('Notifications'),
                    ],
                  ),
                ),
                PopupMenuItem<_ProfileMenuAction>(
                  value: _ProfileMenuAction.logout,
                  child: const Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 12),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Consumer<TeacherController>(
        builder: (context, controller, _) {
          if (_isEditingProfile) {
            return _buildEditMode(context, controller);
          }
          return _buildViewMode(context, controller);
        },
      ),
    );
  }

  Widget _buildViewMode(BuildContext context, TeacherController controller) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                _buildProfileAvatar(photoPath: controller.photoPath, size: 80),
                const SizedBox(height: 16),
                Text(
                  controller.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Professeur',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildProfileStat(
                    context,
                    value: controller.subjects.length.toString(),
                    label: 'Matières',
                    icon: Icons.subject,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProfileStat(
                    context,
                    value: controller.totalClasses.toString(),
                    label: 'Classes',
                    icon: Icons.school,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProfileStat(
                    context,
                    value: controller.gradeEntries
                        .map((g) => g.eleveId)
                        .toSet()
                        .length
                        .toString(),
                    label: 'Élèves',
                    icon: Icons.people,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Personal information section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations personnelles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  value: controller.email,
                ),
                _buildInfoCard(
                  context,
                  icon: Icons.phone,
                  label: 'Téléphone',
                  value: controller.phone.isNotEmpty
                      ? controller.phone
                      : 'Non renseigné',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subjects section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matières enseignées',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.subjects.isEmpty)
                  Text(
                    'Aucune matière renseignée',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.subjects
                        .map(
                          (subject) => Chip(
                            label: Text(subject),
                            backgroundColor: Colors.purple.withOpacity(0.1),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte et sécurité',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Changer le mot de passe',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Classes section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classes assignées',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.classes.length,
                  itemBuilder: (context, index) {
                    final className = controller.classes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.class_, color: Colors.purple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              className,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handleMenuAction(_ProfileMenuAction action) {
    switch (action) {
      case _ProfileMenuAction.edit:
        setState(() {
          _isEditingProfile = true;
        });
        break;
      case _ProfileMenuAction.changePassword:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
        break;
      case _ProfileMenuAction.notifications:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
        break;
      case _ProfileMenuAction.logout:
        _logout(context);
        break;
    }
  }

  Widget _buildEditMode(BuildContext context, TeacherController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifier le profil',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Center(
            child: UserProfileImagePicker(
              initialPhotoDataUrl: _photoDataUrl,
              onImagePicked: (dataUrl) {
                setState(() {
                  _photoDataUrl = dataUrl;
                });
              },
              size: 110,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Prénom',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Nom',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await controller.updateProfile(
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  phone: _phoneController.text,
                  photoPath: _photoDataUrl,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil mis à jour'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _isEditingProfile = false;
                  });
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditingProfile = false;
                });
              },
              icon: const Icon(Icons.close),
              label: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar({
    required String photoPath,
    required double size,
  }) {
    final imageProvider = _buildImageProvider(photoPath);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      child: imageProvider == null
          ? Icon(Icons.person, color: Colors.white, size: size * 0.5)
          : null,
    );
  }

  ImageProvider? _buildImageProvider(String photoPath) {
    if (photoPath.isEmpty) return null;

    if (photoPath.startsWith('http')) {
      return NetworkImage(photoPath);
    }

    if (photoPath.startsWith('data:image')) {
      try {
        final bytes = base64Decode(photoPath.split(',').last);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  Widget _buildProfileStat(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.purple, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.purple),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthController>().logout();
              Navigator.pop(context);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
