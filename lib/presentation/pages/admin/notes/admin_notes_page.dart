import 'package:flutter/material.dart';

class AdminNotesPage extends StatelessWidget {
  const AdminNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Notes')),
      body: const Center(child: Text('À venir')),
    );
  }
}
