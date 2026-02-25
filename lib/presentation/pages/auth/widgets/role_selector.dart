import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onSelect;

  RoleSelector({required this.selectedRole, required this.onSelect});

  final List<Map<String, dynamic>> roles = [
    {
      'value': 'eleve',  // Valeur pour Firestore
      'label': 'Élève',  // Affichage
      'icon': Icons.school,
      'bgColor': Color(0xFFE8F0FE),
      'iconColor': Color(0xFF2B56F5),
    },
    {
      'value': 'enseignant',  // Valeur pour Firestore
      'label': 'Professeur',  // Affichage
      'icon': Icons.person,
      'bgColor': Color(0xFFF4ECFF),
      'iconColor': Color(0xFF8C45F7),
    },
    {
      'value': 'parent',  // Valeur pour Firestore
      'label': 'Parent',  // Affichage
      'icon': Icons.people,
      'bgColor': Color(0xFFE9F7EE),
      'iconColor': Color(0xFF34A853),
    },
    {
      'value': 'admin',  // Valeur pour Firestore
      'label': 'Admin',  // Affichage
      'icon': Icons.admin_panel_settings,
      'bgColor': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFFB8C00),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: roles.map((role) {
        bool isSelected = selectedRole == role['value'];
        return GestureDetector(
          onTap: () => onSelect(role['value']),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isSelected ? role['iconColor'] : role['bgColor'],
                child: Icon(
                  role['icon'],
                  color: isSelected ? Colors.white : role['iconColor'],
                  size: 28,
                ),
              ),
              const SizedBox(height: 5),
              Text(role['label']),
            ],
          ),
        );
      }).toList(),
    );
  }
}
