import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/teacher_controller.dart';
import '../../student/widgets/schedule_card.dart';

class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  static const List<String> _days = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  int _selectedDayIndex = 0; // 0 = Lundi (dayOfWeek = 1)

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final controller = context.read<TeacherController>();
      controller.loadSchedules();
      debugPrint('📱 TeacherTimetableScreen initState - loadSchedules() appelé');
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('📱 Après chargement - schedulesByDay keys: ${controller.schedulesByDay.keys}');
        for (int day = 1; day <= 7; day++) {
          final count = controller.schedulesByDay[day]?.length ?? 0;
          debugPrint('   Jour $day: $count cours');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherController>(
      builder: (context, controller, _) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Days selector with horizontal scroll
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_days.length, (index) {
                        final isSelected = index == _selectedDayIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              _days[index],
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.purple : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedDayIndex = index;
                              });
                            },
                            selectedColor: Colors.purple.withOpacity(0.2),
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide(
                              color: isSelected ? Colors.purple : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Schedules for selected day
                _buildDaySchedule(context, controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaySchedule(BuildContext context, TeacherController controller) {
    final dayOfWeek = _selectedDayIndex + 1; // Lundi = 1
    final daySchedules = controller.schedulesByDay[dayOfWeek] ?? [];
    
    debugPrint('🎯 _buildDaySchedule: _selectedDayIndex=$_selectedDayIndex, dayOfWeek=$dayOfWeek');
    debugPrint('   daySchedules.length=${daySchedules.length}, schedulesByDay.keys=${controller.schedulesByDay.keys.toList()}');

    if (controller.schedules.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun cours assigné',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas d\'emploi de temps pour le moment',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    if (daySchedules.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun cours le ${_days[_selectedDayIndex]}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daySchedules.length,
        itemBuilder: (context, index) {
          return ScheduleCard(schedule: daySchedules[index]);
        },
      ),
    );
  }
}
