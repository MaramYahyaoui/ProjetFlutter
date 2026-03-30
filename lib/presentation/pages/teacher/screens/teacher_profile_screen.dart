import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/teacher_controller.dart';
import '../../../../controllers/auth_controller.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<TeacherController>();
    _firstNameController = TextEditingController(text: controller.firstName);
    _lastNameController = TextEditingController(text: controller.lastName);
    _phoneController = TextEditingController(text: controller.phone);
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
          if (!_isEditingProfile)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 12),
                      Text('Modifier'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _isEditingProfile = true;
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 12),
                      Text('Déconnexion'),
                    ],
                  ),
                  onTap: () {
                    _logout(context);
                  },
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    image: controller.photoPath.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(controller.photoPath),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: controller.photoPath.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        )
                      : null,
                ),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                  value: controller.phone.isNotEmpty ? controller.phone : 'Non renseigné',
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                        .map((subject) => Chip(
                          label: Text(subject),
                          backgroundColor: Colors.purple.withOpacity(0.1),
                        ))
                        .toList(),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                          Icon(
                            Icons.class_,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              className,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
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

  Widget _buildEditMode(BuildContext context, TeacherController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifier le profil',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildProfileStat(BuildContext context,
      {required String value, required String label, required IconData icon}) {
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildInfoCard(BuildContext context,
      {required IconData icon, required String label, required String value}) {
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
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
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
