import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/student_controller.dart';
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
  ];

  final Map<String, String> _shortLabels = const {
    'Lundi': 'Lun',
    'Mardi': 'Mar',
    'Mercredi': 'Mer',
    'Jeudi': 'Jeu',
    'Vendredi': 'Ven',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final todayIndex = DateTime.now().weekday;
    final todayIndexClamped = todayIndex >= 1 && todayIndex <= 5
        ? todayIndex
        : 1;
    _selectedDay = _days[todayIndexClamped - 1];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudentController>(context);

    final schedules = controller.schedules[_selectedDay] ?? [];
    final weekLabel = _buildWeekLabel();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emploi du temps',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weekLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.calendar_month_outlined),
                      color: const Color(0xFF2F5EDB),
                      iconSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = day == _selectedDay;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2F5EDB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2F5EDB)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _shortLabels[day] ?? day,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: schedules.isEmpty
                  ? _EmptyScheduleState(
                      dayLabel: _shortLabels[_selectedDay] ?? _selectedDay,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: schedules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return ScheduleCard(schedule: schedules[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildWeekLabel() {
    final now = DateTime.now();
    const months = [
      '',
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return 'Semaine du ${now.day} ${months[now.month]}';
  }
}

class _EmptyScheduleState extends StatelessWidget {
  final String dayLabel;

  const _EmptyScheduleState({required this.dayLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF2F5EDB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_outlined,
                size: 38,
                color: Color(0xFF2F5EDB),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aucun cours prévu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun cours n\'est programmé pour $dayLabel.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
