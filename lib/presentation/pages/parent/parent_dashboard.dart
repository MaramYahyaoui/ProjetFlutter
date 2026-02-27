// lib/presentation/pages/parent/parent_dashboard.dart
import 'package:flutter/material.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord - Parent')),
      body: const Center(child: Text('Bienvenue Parent !')),
    );
  }
}