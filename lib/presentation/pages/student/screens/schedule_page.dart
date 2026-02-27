import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/student_controller.dart';
import '../../../../models/emploi.dart';
import '../widgets/schedule_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String _selectedDay = 'Lundi';

  final List<String> _days = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudentController>(context);

    final schedules =
        controller.schedules[_selectedDay] ?? [];

    return Scaffold(
      body: Column(
        children: [

          // ===== DAY SELECTOR =====
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final isSelected = day == _selectedDay;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : Colors.grey[200],
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ===== LIST =====
          Expanded(
            child: schedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun cours ce jour',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      return ScheduleCard(
                          schedule: schedules[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
