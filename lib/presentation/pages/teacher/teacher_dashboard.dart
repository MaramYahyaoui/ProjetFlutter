// lib/presentation/pages/teacher/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/teacher_controller.dart';
import '../../../controllers/auth_controller.dart';
import 'screens/teacher_home_screen.dart';
import 'screens/teacher_classes_screen.dart';
import 'screens/grade_entry_screen.dart';
import 'screens/teacher_statistics_screen.dart';
import 'screens/teacher_profile_screen.dart';
import 'screens/teacher_timetable_screen.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final uid = authController.user?.id ?? '';

    return ChangeNotifierProvider(
      create: (_) => TeacherController(uid)..init(),
      child: const _TeacherDashboardContent(),
    );
  }
}

class _TeacherDashboardContent extends StatefulWidget {
  const _TeacherDashboardContent();

  @override
  State<_TeacherDashboardContent> createState() =>
      _TeacherDashboardContentState();
}

class _TeacherDashboardContentState extends State<_TeacherDashboardContent> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: [
            const TeacherHomeScreen(),
            const TeacherClassesScreen(),
            const GradeEntryScreen(),
            const TeacherTimetableScreen(),
            const TeacherStatisticsScreen(),
            const TeacherProfileScreen(),
          ][_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Classes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: 'Emploi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}


