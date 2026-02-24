import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onSelect;

  RoleSelector({required this.selectedRole, required this.onSelect});

  final List<Map<String, dynamic>> roles = [
    {
      'name': 'Élève',
      'icon': Icons.school,
      'bgColor': Color(0xFFE8F0FE),
      'iconColor': Color(0xFF2B56F5),
    },
    {
      'name': 'Professeur',
      'icon': Icons.person,
      'bgColor': Color(0xFFF4ECFF),
      'iconColor': Color(0xFF8C45F7),
    },
    {
      'name': 'Parent',
      'icon': Icons.people,
      'bgColor': Color(0xFFE9F7EE),
      'iconColor': Color(0xFF34A853),
    },
    {
      'name': 'Admin',
      'icon': Icons.admin_panel_settings,
      'bgColor': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFFB8C00),
    },
    {
      'name': 'Vie Scolaire',
      'icon': Icons.calendar_today,
      'bgColor': Color(0xFFE0F7FA),
      'iconColor': Color(0xFF0097A7),
      
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: roles.map((role) {
        bool isSelected = selectedRole == role['name'];
        return GestureDetector(
          onTap: () => onSelect(role['name']),
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
              Text(role['name']),
            ],
          ),
        );
      }).toList(),
    );
  }
}
