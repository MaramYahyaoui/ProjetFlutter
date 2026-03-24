// lib/presentation/pages/teacher/teacher_dashboard.dart
import 'package:flutter/material.dart';

import 'timetable/teacher_timetable_page.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord - Prof')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeacherTimetablePage()),
            );
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Emploi du temps'),
        ),
      ),
    );
  }
}
