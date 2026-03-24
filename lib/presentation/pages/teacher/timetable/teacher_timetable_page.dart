import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../student/widgets/schedule_card.dart';
import '../../../../models/emploi.dart';

class TeacherTimetablePage extends StatefulWidget {
  const TeacherTimetablePage({super.key});

  @override
  State<TeacherTimetablePage> createState() => _TeacherTimetablePageState();
}

class _TeacherTimetablePageState extends State<TeacherTimetablePage> {
  static const _days = <String>[
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  String _selectedDay = _days.first;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mon emploi du temps',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: uid == null
          ? const _CenteredMessage(
              icon: Icons.lock_outline,
              title: 'Non connecté',
              message: "Connectez-vous pour voir l'emploi du temps.",
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('emplois')
                  .where('type', isEqualTo: 'professeur')
                  .where('ownerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _CenteredMessage(
                    icon: Icons.error_outline,
                    title: 'Erreur',
                    message: snapshot.error.toString(),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schedules =
                    snapshot.data!.docs
                        .map((d) => Schedule.fromFirestore(d))
                        .toList(growable: false)
                      ..sort((a, b) {
                        final day = a.dayOfWeek.compareTo(b.dayOfWeek);
                        if (day != 0) return day;
                        return a.startTime.compareTo(b.startTime);
                      });

                final selectedIndex = _days.indexOf(_selectedDay) + 1;
                final daySchedules = schedules
                    .where((s) => s.dayOfWeek == selectedIndex)
                    .toList(growable: false);

                return Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _days
                              .map((d) {
                                final selected = d == _selectedDay;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(d),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _selectedDay = d),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                    ),
                    Expanded(
                      child: daySchedules.isEmpty
                          ? const _CenteredMessage(
                              icon: Icons.schedule_outlined,
                              title: 'Aucun créneau',
                              message: "Aucun cours prévu pour ce jour.",
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                16,
                              ),
                              itemCount: daySchedules.length,
                              itemBuilder: (context, index) {
                                return ScheduleCard(
                                  schedule: daySchedules[index],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
