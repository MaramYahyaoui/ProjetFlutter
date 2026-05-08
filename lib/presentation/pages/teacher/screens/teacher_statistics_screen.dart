import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/teacher_controller.dart';

class TeacherStatisticsScreen extends StatefulWidget {
  const TeacherStatisticsScreen({super.key});

  @override
  State<TeacherStatisticsScreen> createState() =>
      _TeacherStatisticsScreenState();
}

class _TeacherStatisticsScreenState extends State<TeacherStatisticsScreen> {
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques'), elevation: 0),
      body: Consumer<TeacherController>(
        builder: (context, controller, _) {
          if (controller.classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune classe assignée',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          // Set default class if not selected
          _selectedClassId ??= controller.classes.isNotEmpty
              ? controller.classes.first
              : null;

          if (_selectedClassId == null) {
            return const Center(child: Text('Aucune classe disponible'));
          }

          final stats = controller.currentClassStatistics;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class selector
                DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'Sélectionner une classe',
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: controller.classes
                      .map(
                        (className) => DropdownMenuItem(
                          value: className,
                          child: Text(className),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _selectedClassId = value;
                      });
                      await controller.selectClass(value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Key statistics
                Text(
                  'Informations sur $_selectedClassId',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (stats == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Stats grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.trending_up,
                          value: stats.average.toStringAsFixed(2),
                          label: 'Moyenne classe',
                          color: Colors.orange,
                          suffix: '/20',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.show_chart,
                          value: stats.median.toStringAsFixed(2),
                          label: 'Médiane',
                          color: Colors.teal,
                          suffix: '/20',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.check_circle,
                          value: stats.successRate.toStringAsFixed(1),
                          label: 'Taux réussite',
                          color: Colors.green,
                          suffix: '%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.people,
                          value: stats.studentCount.toString(),
                          label: 'Élèves',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.assessment,
                          value: stats.minScore.toStringAsFixed(1),
                          label: 'Note min',
                          color: Colors.red,
                          suffix: '/20',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.star,
                          value: stats.maxScore.toStringAsFixed(1),
                          label: 'Note max',
                          color: Colors.amber,
                          suffix: '/20',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Score distribution
                  _buildScoreDistribution(context, stats),
                  const SizedBox(height: 24),

                  // Score evolution
                  _buildScoreEvolution(context),
                  const SizedBox(height: 24),

                  // Top performers
                  _buildTopPerformers(context, controller, _selectedClassId),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    String suffix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(BuildContext context, stats) {
    // Map des couleurs et des données réelles
    final distributionData = [
      ('0-5', stats.scoreDistribution['0-5'] ?? 0, Colors.red),
      ('5-10', stats.scoreDistribution['5-10'] ?? 0, Colors.orange),
      ('10-14', stats.scoreDistribution['10-14'] ?? 0, Colors.yellow),
      ('14-17', stats.scoreDistribution['14-17'] ?? 0, Colors.lightGreen),
      ('17-20', stats.scoreDistribution['17-20'] ?? 0, Colors.green),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des notes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: distributionData.map((data) {
              return _buildScoreRangeCard(context, data.$1, data.$3, data.$2);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRangeCard(
    BuildContext context,
    String range,
    Color color,
    int count,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(range, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildScoreEvolution(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution de la moyenne',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Fake chart for now
          SizedBox(
            height: 200,
            child: CustomPaint(painter: LineChartPainter()),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(
    BuildContext context,
    TeacherController controller,
    selectedClass,
  ) {
    // Récupérer les élèves avec leurs meilleures notes moyennes
    final gradesByStudent = <String, List<double>>{};
    for (final grade in controller.gradeEntries) {
      gradesByStudent.putIfAbsent(grade.eleveId, () => []).add(grade.note);
    }

    // Calculer la moyenne par élève et trier
    final studentAverages = gradesByStudent.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return (eleveId: e.key, average: avg);
    }).toList()..sort((a, b) => b.average.compareTo(a.average));

    // Prendre les top 3
    final topPerformers = studentAverages.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meilleures performances',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (topPerformers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune donnée disponible',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Column(
              children: List.generate(topPerformers.length, (index) {
                final performer = topPerformers[index];
                final medalColor = index == 0
                    ? Colors.yellow
                    : index == 1
                    ? Colors.grey
                    : Colors.orange;
                return Column(
                  children: [
                    _buildPerformerRow(
                      context,
                      index + 1,
                      performer.eleveId, // ID élève pour maintenant
                      performer.average.toStringAsFixed(2),
                      medalColor,
                    ),
                    if (index < topPerformers.length - 1)
                      const SizedBox(height: 12),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformerRow(
    BuildContext context,
    int position,
    String name,
    String score,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              position.toString(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          score,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.35);
    path.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
