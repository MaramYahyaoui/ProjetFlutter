import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'classes/classes_page.dart';
import 'timetable/timetable_page.dart';
import 'users/users_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  String _formatShortDay(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[date.weekday - 1];
  }

  String _formatFrenchDate(DateTime date) {
    const days = [
      '',
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
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
    return '${days[date.weekday]} ${date.day} ${months[date.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(
                    title: 'Espace Administration',
                    subtitle: 'Admin',
                    dateLabel: _formatFrenchDate(now),
                  ),
                  const SizedBox(height: 84),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('utilisateurs')
                          .snapshots(),
                      builder: (context, usersSnapshot) {
                        if (usersSnapshot.hasError) {
                          return _CenteredMessage(
                            icon: Icons.error_outline,
                            title: 'Erreur',
                            message: usersSnapshot.error.toString(),
                          );
                        }

                        if (!usersSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final userDocs = usersSnapshot.data!.docs;
                        final users = userDocs
                            .map((d) => _AdminUserLite.fromDoc(d))
                            .toList(growable: false);
                        final usersById = {for (final u in users) u.id: u};

                        final totalUsers = users.length;
                        final students = users
                            .where((u) => u.isStudent)
                            .toList();
                        final teachers = users
                            .where((u) => u.isTeacher)
                            .toList();
                        final classes = <String>{
                          for (final s in students)
                            if (s.classe != null && s.classe!.trim().isNotEmpty)
                              s.classe!.trim(),
                        };

                        final nowDateOnly = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                        final last5Days = List<DateTime>.generate(
                          5,
                          (i) => nowDateOnly.subtract(Duration(days: 4 - i)),
                          growable: false,
                        );

                        final activityLabels = last5Days
                            .map(_formatShortDay)
                            .toList(growable: false);
                        final activityValues = last5Days
                            .map((day) {
                              final next = day.add(const Duration(days: 1));
                              int count = 0;
                              for (final u in users) {
                                final createdAt = u.createdAt;
                                if (createdAt == null) continue;
                                if (!createdAt.isBefore(next) &&
                                    createdAt != next)
                                  continue;
                                if (createdAt.isBefore(day)) continue;
                                count++;
                              }
                              return count.toDouble();
                            })
                            .toList(growable: false);

                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: FirebaseFirestore.instance
                              .collection('notes')
                              .snapshots(),
                          builder: (context, notesSnapshot) {
                            final noteDocs =
                                notesSnapshot.data?.docs ?? const [];

                            final notesByClass = <String, int>{};
                            final teacherIdsWithNotes = <String>{};

                            for (final doc in noteDocs) {
                              final data = doc.data();
                              final eleveId = data['eleveId'] as String?;
                              if (eleveId != null) {
                                final classe = usersById[eleveId]?.classe;
                                if (classe != null &&
                                    classe.trim().isNotEmpty) {
                                  notesByClass.update(
                                    classe.trim(),
                                    (v) => v + 1,
                                    ifAbsent: () => 1,
                                  );
                                }
                              }

                              final profId =
                                  (data['professeurId'] as String?) ??
                                  (data['enseignantId'] as String?) ??
                                  (data['teacherId'] as String?);
                              if (profId != null && profId.trim().isNotEmpty) {
                                teacherIdsWithNotes.add(profId.trim());
                              }
                            }

                            final missingTeachers = teachers
                                .where(
                                  (t) => !teacherIdsWithNotes.contains(t.id),
                                )
                                .length;

                            final classEntries = notesByClass.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key));
                            final topClasses = classEntries
                                .take(5)
                                .toList(growable: false);
                            final barLabels = topClasses
                                .map((e) => e.key)
                                .toList(growable: false);
                            final barValues = topClasses.isEmpty
                                ? const <double>[]
                                : topClasses
                                      .map((e) => e.value.toDouble())
                                      .toList(growable: false);

                            final maxBar = barValues.isEmpty
                                ? 1.0
                                : barValues.reduce(math.max);
                            final barPercentValues = barValues
                                .map(
                                  (v) => (v / maxBar * 100)
                                      .clamp(0.0, 100.0)
                                      .toDouble(),
                                )
                                .toList(growable: false);

                            return Column(
                              children: [
                                _StatsGrid(
                                  stats: [
                                    _StatData(
                                      icon: Icons.people_outline,
                                      value: '$totalUsers',
                                      label: 'Utilisateurs',
                                      sublabel: 'Total',
                                      accent: const Color(0xFFFF7A00),
                                    ),
                                    _StatData(
                                      icon: Icons.school_outlined,
                                      value: '${students.length}',
                                      label: 'Élèves',
                                      sublabel: 'Inscrits',
                                      accent: const Color(0xFF3B82F6),
                                    ),
                                    _StatData(
                                      icon: Icons.person_outline,
                                      value: '${teachers.length}',
                                      label: 'Professeurs',
                                      sublabel: 'Actifs',
                                      accent: const Color(0xFF22C55E),
                                    ),
                                    _StatData(
                                      icon: Icons.apartment_outlined,
                                      value: '${classes.length}',
                                      label: 'Classes',
                                      sublabel: 'Cette année',
                                      accent: const Color(0xFF8B5CF6),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (missingTeachers > 0) ...[
                                  _AlertBanner(
                                    text:
                                        "$missingTeachers professeurs n'ont pas saisi leurs notes",
                                    actionLabel: 'Voir',
                                    onAction: () {},
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _ChartCard(
                                  title: 'Activité utilisateurs',
                                  child: SizedBox(
                                    height: 160,
                                    child: _LineChart(
                                      labels: activityLabels,
                                      values: activityValues,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _ChartCard(
                                  title: 'Progression saisie des notes',
                                  child: SizedBox(
                                    height: 180,
                                    child: _BarChart(
                                      labels: barLabels.isEmpty
                                          ? const [
                                              '2A',
                                              '2B',
                                              '1S',
                                              '1L',
                                              'TES',
                                            ]
                                          : barLabels,
                                      values: barPercentValues.isEmpty
                                          ? const [0, 0, 0, 0, 0]
                                          : barPercentValues,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 148,
                child: _QuickActionsCard(
                  actions: const [
                    _QuickActionData(
                      label: 'Ajouter\nuser',
                      icon: Icons.person_add_alt_1_outlined,
                      bg: Color(0xFFFFF3E0),
                      fg: Color(0xFFFF7A00),
                      action: _QuickActionAction.users,
                    ),
                    _QuickActionData(
                      label: 'Classes',
                      icon: Icons.account_balance_outlined,
                      bg: Color(0xFFEFF6FF),
                      fg: Color(0xFF3B82F6),
                      action: _QuickActionAction.classes,
                    ),
                    _QuickActionData(
                      label: 'Emploi\ndu temps',
                      icon: Icons.schedule_outlined,
                      bg: Color(0xFFE9F7EE),
                      fg: Color(0xFF22C55E),
                      action: _QuickActionAction.timetable,
                    ),
                    _QuickActionData(
                      label: 'Paramètres',
                      icon: Icons.settings_outlined,
                      bg: Color(0xFFF4ECFF),
                      fg: Color(0xFF8B5CF6),
                      action: _QuickActionAction.settings,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _QuickActionAction { users, classes, timetable, settings }

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final String dateLabel;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFF4D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dateLabel,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final _QuickActionAction action;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.action,
  });
}

class _QuickActionsCard extends StatelessWidget {
  final List<_QuickActionData> actions;

  const _QuickActionsCard({required this.actions});

  void _handle(BuildContext context, _QuickActionAction action) {
    switch (action) {
      case _QuickActionAction.users:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdminUsersPage()));
        return;
      case _QuickActionAction.classes:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdminClassesPage()));
        return;
      case _QuickActionAction.timetable:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdminTimetablePage()));
        return;
      case _QuickActionAction.settings:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions
            .map(
              (a) => Expanded(
                child: _QuickAction(
                  label: a.label,
                  icon: a.icon,
                  bg: a.bg,
                  fg: a.fg,
                  onTap: () => _handle(context, a.action),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: fg, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color accent;
  final String? badge;

  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.accent,
    this.badge,
  });
}

class _StatsGrid extends StatelessWidget {
  final List<_StatData> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.length != 4) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(data: stats[0])),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(data: stats[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(data: stats[2])),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(data: stats[3])),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.accent, size: 18),
              ),
              const Spacer(),
              if (data.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '↗ ${data.badge}',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.sublabel,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _AlertBanner({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7A00).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A00).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFFFF7A00),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;

  const _LineChart({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(labels: labels, values: values),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;

  _LineChartPainter({required this.labels, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final paddingLeft = 26.0;
    final paddingRight = 10.0;
    final paddingTop = 8.0;
    final paddingBottom = 24.0;

    final chartRect = Rect.fromLTWH(
      paddingLeft,
      paddingTop,
      math.max(0, size.width - paddingLeft - paddingRight),
      math.max(0, size.height - paddingTop - paddingBottom),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFEAECEF)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = chartRect.top + chartRect.height * (i / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    const yLabels = ['80', '60', '40', '20', '0'];
    for (var i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFF7A7A7A)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = chartRect.top + chartRect.height * (i / 4) - tp.height / 2;
      tp.paint(canvas, Offset(0, y));
    }

    if (values.isEmpty) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x =
          chartRect.left +
          chartRect.width * (i / math.max(1, values.length - 1));
      final normalized = (values[i] - minV) / span;
      final y = chartRect.bottom - chartRect.height * normalized;
      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFFFF7A00);
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(
        p,
        7,
        Paint()..color = const Color(0xFFFF7A00).withOpacity(0.12),
      );
    }

    final xLabels = labels.take(values.length).toList(growable: false);
    for (var i = 0; i < xLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: xLabels[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFF7A7A7A)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final x =
          chartRect.left +
          chartRect.width * (i / math.max(1, xLabels.length - 1)) -
          tp.width / 2;
      tp.paint(canvas, Offset(x, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.labels != labels || oldDelegate.values != values;
  }
}

class _BarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;

  const _BarChart({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(labels: labels, values: values),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;

  _BarChartPainter({required this.labels, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final paddingLeft = 14.0;
    final paddingRight = 14.0;
    final paddingTop = 8.0;
    final paddingBottom = 24.0;

    final chartRect = Rect.fromLTWH(
      paddingLeft,
      paddingTop,
      math.max(0, size.width - paddingLeft - paddingRight),
      math.max(0, size.height - paddingTop - paddingBottom),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFEAECEF)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = chartRect.top + chartRect.height * (i / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    if (values.isEmpty) return;
    final maxV = values.reduce(math.max);
    final safeMax = maxV <= 0 ? 1.0 : maxV;

    final barCount = math.min(labels.length, values.length);
    final gap = 10.0;
    final barWidth = (chartRect.width - gap * (barCount - 1)) / barCount;

    final barPaint = Paint()..color = const Color(0xFFFF7A00);
    for (var i = 0; i < barCount; i++) {
      final v = values[i];
      final h = chartRect.height * (v / safeMax);
      final left = chartRect.left + i * (barWidth + gap);
      final top = chartRect.bottom - h;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, h),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, barPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFF7A7A7A)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(left + barWidth / 2 - tp.width / 2, size.height - tp.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.labels != labels || oldDelegate.values != values;
  }
}

class _AdminUserLite {
  final String id;
  final String? role;
  final String? classe;
  final DateTime? createdAt;

  const _AdminUserLite({
    required this.id,
    required this.role,
    required this.classe,
    required this.createdAt,
  });

  factory _AdminUserLite.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final data = d.data();

    final rawRole =
        (data['role'] as String?) ??
        (data['type'] as String?) ??
        (data['userType'] as String?) ??
        (data['profil'] as String?);

    final rawClasse =
        (data['classe'] as String?) ??
        (data['class'] as String?) ??
        (data['classeId'] as String?);

    final rawCreatedAt =
        data['createdAt'] ?? data['created_at'] ?? data['dateCreation'];

    DateTime? createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    }

    return _AdminUserLite(
      id: d.id,
      role: rawRole,
      classe: rawClasse,
      createdAt: createdAt,
    );
  }

  bool get isStudent {
    final r = role?.toLowerCase().trim();
    return r == 'eleve' || r == 'élève' || r == 'student';
  }

  bool get isTeacher {
    final r = role?.toLowerCase().trim();
    return r == 'prof' ||
        r == 'professeur' ||
        r == 'teacher' ||
        r == 'enseignant';
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
