import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/services/report_service.dart';
import '../../../../models/report_model.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

enum _ReportPeriod { all, last7Days, last30Days, last90Days }

class _AdminReportsPageState extends State<AdminReportsPage> {
  _ReportPeriod _selectedPeriod = _ReportPeriod.all;

  String _formatShortDay(DateTime date) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[date.weekday - 1];
  }

  String _periodLabel(_ReportPeriod period) {
    switch (period) {
      case _ReportPeriod.all:
        return 'Tout';
      case _ReportPeriod.last7Days:
        return '7 jours';
      case _ReportPeriod.last30Days:
        return '30 jours';
      case _ReportPeriod.last90Days:
        return '90 jours';
    }
  }

  int? _periodDays(_ReportPeriod period) {
    switch (period) {
      case _ReportPeriod.all:
        return null;
      case _ReportPeriod.last7Days:
        return 7;
      case _ReportPeriod.last30Days:
        return 30;
      case _ReportPeriod.last90Days:
        return 90;
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterNotes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notes,
  ) {
    final days = _periodDays(_selectedPeriod);
    if (days == null) return notes;

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    return notes
        .where((doc) {
          final rawDate = doc.data()['date'];
          if (rawDate is! Timestamp) return false;
          final noteDate = rawDate.toDate();
          return !noteDate.isBefore(start);
        })
        .toList(growable: false);
  }

  Future<void> _exportCsv({
    required String periodLabel,
    required int studentsCount,
    required int teachersCount,
    required int parentsCount,
    required int classesCount,
    required double avg,
    required double successRate,
    required int notesCount,
    required List<String> activityLabels,
    required List<double> activityValues,
    required List<String> classLabels,
    required List<double> classValues,
  }) async {
    final buffer = StringBuffer()
      ..writeln('Rapport,${periodLabel.replaceAll(',', ' ')}')
      ..writeln('Indicateur,Valeur')
      ..writeln('Élèves,$studentsCount')
      ..writeln('Professeurs,$teachersCount')
      ..writeln('Parents,$parentsCount')
      ..writeln('Classes,$classesCount')
      ..writeln('Moyenne générale,${avg.toStringAsFixed(2)}/20')
      ..writeln('Taux de réussite,${successRate.toStringAsFixed(1)}%')
      ..writeln('Nombre de notes,$notesCount')
      ..writeln()
      ..writeln('Activité')
      ..writeln('Jour,Notes');

    for (var i = 0; i < activityLabels.length; i++) {
      buffer.writeln(
        '${activityLabels[i]},${activityValues[i].toStringAsFixed(0)}',
      );
    }

    buffer
      ..writeln()
      ..writeln('Répartition par classe')
      ..writeln('Classe,Notes');

    for (var i = 0; i < classLabels.length; i++) {
      buffer.writeln('${classLabels[i]},${classValues[i].toStringAsFixed(0)}');
    }

    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}rapport_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exporté: ${file.path}')));
  }

  Future<void> _exportPdf({
    required String periodLabel,
    required int studentsCount,
    required int teachersCount,
    required int parentsCount,
    required int classesCount,
    required double avg,
    required double successRate,
    required int notesCount,
    required List<String> activityLabels,
    required List<double> activityValues,
    required List<String> classLabels,
    required List<double> classValues,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.robotoRegular(),
            bold: await PdfGoogleFonts.robotoBold(),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Rapport administratif',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Période: $periodLabel'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: const ['Indicateur', 'Valeur'],
            data: [
              ['Élèves', '$studentsCount'],
              ['Professeurs', '$teachersCount'],
              ['Parents', '$parentsCount'],
              ['Classes', '$classesCount'],
              ['Moyenne générale', '${avg.toStringAsFixed(2)}/20'],
              ['Taux de réussite', '${successRate.toStringAsFixed(1)}%'],
              ['Nombre de notes', '$notesCount'],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Activité',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: const ['Jour', 'Notes'],
            data: List.generate(
              activityLabels.length,
              (i) => [activityLabels[i], activityValues[i].toStringAsFixed(0)],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Répartition par classe',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: const ['Classe', 'Notes'],
            data: List.generate(
              classLabels.length,
              (i) => [classLabels[i], classValues[i].toStringAsFixed(0)],
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rapports',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vue d’ensemble',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatShortDay(now)} ${now.day}/${now.month}/${now.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ReportPeriod.values
                      .map((period) {
                        final selected = _selectedPeriod == period;
                        return ChoiceChip(
                          label: Text(_periodLabel(period)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedPeriod = period);
                          },
                          selectedColor: const Color(
                            0xFFFF7A00,
                          ).withOpacity(0.14),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFFFF7A00)
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                FutureBuilder<ReportModel>(
                  future: () {
                    final days = _periodDays(_selectedPeriod);
                    if (days == null) return ReportService().computeReport();
                    final now = DateTime.now();
                    final start = DateTime(
                      now.year,
                      now.month,
                      now.day,
                    ).subtract(Duration(days: days - 1));
                    final end = DateTime(now.year, now.month, now.day);
                    return ReportService().computeReport(from: start, to: end);
                  }(),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return _SectionCard(
                        title: 'Erreur',
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Erreur: ${snap.error}'),
                        ),
                      );
                    }

                    final model = snap.data!;

                    final activityLabels = model.activityLabels;
                    final activityValues = model.activityValues;
                    final reportBarLabels = model.classLabels.isEmpty
                        ? const ['A', 'B', 'C', 'D', 'E']
                        : model.classLabels;
                    final reportBarValues = model.classValues.isEmpty
                        ? const [0.0, 0.0, 0.0, 0.0, 0.0]
                        : model.classValues;

                    final maxBar = reportBarValues.isEmpty
                        ? 1.0
                        : reportBarValues.reduce(math.max);
                    final barPercentValues = reportBarValues
                        .map(
                          (v) =>
                              (v / maxBar * 100).clamp(0.0, 100.0).toDouble(),
                        )
                        .toList(growable: false);

                    return Column(
                      children: [
                        _SectionCard(
                          title: 'Indicateurs clés',
                          child: _StatsGrid(
                            stats: [
                              _StatData(
                                icon: Icons.people_outline,
                                value: '${model.studentsCount}',
                                label: 'Élèves',
                                sublabel: 'Inscrits',
                                accent: const Color(0xFFFF7A00),
                              ),
                              _StatData(
                                icon: Icons.person_outline,
                                value: '${model.teachersCount}',
                                label: 'Professeurs',
                                sublabel: 'Actifs',
                                accent: const Color(0xFF3B82F6),
                              ),
                              _StatData(
                                icon: Icons.family_restroom_outlined,
                                value: '${model.parentsCount}',
                                label: 'Parents',
                                sublabel: 'Comptes liés',
                                accent: const Color(0xFF22C55E),
                              ),
                              _StatData(
                                icon: Icons.apartment_outlined,
                                value: '${model.classesCount}',
                                label: 'Classes',
                                sublabel: 'Référencées',
                                accent: const Color(0xFF8B5CF6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Performance scolaire',
                          child: Column(
                            children: [
                              _MiniMetricRow(
                                label: 'Moyenne générale',
                                value: '${model.average.toStringAsFixed(2)}/20',
                              ),
                              const SizedBox(height: 8),
                              _MiniMetricRow(
                                label: 'Taux de réussite',
                                value:
                                    '${model.successRate.toStringAsFixed(1)}%',
                              ),
                              const SizedBox(height: 8),
                              _MiniMetricRow(
                                label: 'Nombre de notes',
                                value: '${model.notesCount}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Activité',
                          child: SizedBox(
                            height: 160,
                            child: _LineChart(
                              labels: activityLabels,
                              values: activityValues,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Répartition des notes par classe',
                          child: SizedBox(
                            height: 180,
                            child: _BarChart(
                              labels: reportBarLabels,
                              values: barPercentValues,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Actions rapides',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _ActionChip(
                                icon: Icons.download_outlined,
                                label: 'Exporter PDF',
                                onTap: () => _exportPdf(
                                  periodLabel: _periodLabel(_selectedPeriod),
                                  studentsCount: model.studentsCount,
                                  teachersCount: model.teachersCount,
                                  parentsCount: model.parentsCount,
                                  classesCount: model.classesCount,
                                  avg: model.average,
                                  successRate: model.successRate,
                                  notesCount: model.notesCount,
                                  activityLabels: activityLabels,
                                  activityValues: activityValues,
                                  classLabels: reportBarLabels,
                                  classValues: reportBarValues,
                                ),
                              ),
                              _ActionChip(
                                icon: Icons.table_chart_outlined,
                                label: 'Exporter CSV',
                                onTap: () => _exportCsv(
                                  periodLabel: _periodLabel(_selectedPeriod),
                                  studentsCount: model.studentsCount,
                                  teachersCount: model.teachersCount,
                                  parentsCount: model.parentsCount,
                                  classesCount: model.classesCount,
                                  avg: model.average,
                                  successRate: model.successRate,
                                  notesCount: model.notesCount,
                                  activityLabels: activityLabels,
                                  activityValues: activityValues,
                                  classLabels: reportBarLabels,
                                  classValues: reportBarValues,
                                ),
                              ),
                              _ActionChip(
                                icon: Icons.bar_chart_outlined,
                                label: 'Rapport trimestriel',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isStudent(Map<String, dynamic> user) {
    final role = (user['role'] ?? user['type'] ?? '').toString().toLowerCase();
    return role.contains('eleve') || role.contains('student');
  }

  bool _isTeacher(Map<String, dynamic> user) {
    final role = (user['role'] ?? user['type'] ?? '').toString().toLowerCase();
    return role.contains('enseignant') || role.contains('teacher');
  }

  bool _isParent(Map<String, dynamic> user) {
    final role = (user['role'] ?? user['type'] ?? '').toString().toLowerCase();
    return role.contains('parent') || role.contains('tuteur');
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color accent;

  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.accent,
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

class _MiniMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Chip(
        avatar: Icon(icon, size: 18, color: const Color(0xFFFF7A00)),
        label: Text(label),
        backgroundColor: const Color(0xFFFFF3E0),
        side: BorderSide(color: const Color(0xFFFF7A00).withOpacity(0.18)),
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
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.labels != labels || oldDelegate.values != values;
  }
}
