import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/student_controller.dart';
import '../../../../models/note_model.dart';
import '../../../../models/emploi.dart';
import '../screens/notes_page.dart';
import '../screens/schedule_page.dart';
import '../screens/homework_page.dart';
import '../widgets/schedule_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
              ? _buildDashboard(controller)
              : _selectedIndex == 1
                  ? const NotesPage()
                  : _selectedIndex == 2
                      ? const SchedulePage()
                      : const HomeworkPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================= BOTTOM NAV =================

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', 0),
              _buildNavItem(Icons.grade_rounded, 'Notes', 1),
              _buildNavItem(Icons.calendar_today_rounded, 'Emploi', 2),
              _buildNavItem(Icons.assignment_rounded, 'Devoirs', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4285F4) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DASHBOARD =================

  Widget _buildDashboard(StudentController controller) {
    final notes = controller.notes;
    final schedules = controller.schedules;
    final pendingHomeworks = controller.getPendingHomeworks();
    final average = controller.getAverage();

    final today = DateTime.now().weekday;
    final dayName = _getDayName(today);
    final todayCourses = schedules[dayName] ?? [];

    Schedule? nextCourse;

    if (todayCourses.isNotEmpty) {
      final now = TimeOfDay.now();

      for (var course in todayCourses) {
        final parts = course.startTime.split(':');
        final courseTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        if (courseTime.hour > now.hour ||
            (courseTime.hour == now.hour &&
                courseTime.minute > now.minute)) {
          nextCourse = course;
          break;
        }
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== HEADER =====
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF2962FF)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Dashboard Élève',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ===== PROCHAIN COURS =====
                  if (nextCourse != null)
                    ScheduleCard(schedule: nextCourse)
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Aucun cours restant aujourd'hui",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ===== STATS =====
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.trending_up,
                          value: average.toStringAsFixed(1),
                          label: 'Moyenne /20',
                          color: const Color(0xFF00BFA5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.assignment,
                          value: pendingHomeworks.length.toString(),
                          label: 'Devoirs à rendre',
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===== NOTES RECENTES =====
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notes récentes',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedIndex = 1),
                        child: const Text("Voir tout"),
                      )
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (notes.isEmpty)
                    const Text("Aucune note disponible")
                  else
                    ...notes
                        .take(3)
                        .map((note) => _buildCompactNoteCard(note)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UTILS =================

  String _getDayName(int weekday) {
    const days = [
      '',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return days[weekday];
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildCompactNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(note.matiere,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            note.note.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
