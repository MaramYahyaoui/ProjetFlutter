// lib/presentation/pages/teacher/teacher_dashboard.dart
import 'package:flutter/material.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord - Prof')),
      body: const Center(child: Text('Bienvenue Professeur !')),
    );
  }
}