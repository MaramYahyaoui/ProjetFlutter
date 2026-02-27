// lib/presentation/pages/admin/admin_dashboard.dart
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord - Admin')),
      body: const Center(child: Text('Bienvenue Admin !')),
    );
  }
}