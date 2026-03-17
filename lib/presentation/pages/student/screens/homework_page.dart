import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/student_controller.dart';
import '../../../../models/homework_model.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  String _selectedFilter = 'Tous';
  
  final List<String> _filters = ['Tous', 'À faire', 'Rendus'];

  // Subject color mapping
  final Map<String, Color> _subjectColors = {
    'Mathématiques': Colors.blue,
    'Physique-Chimie': Colors.purple,
    'Français': Colors.orange,
    'Histoire-Géographie': Colors.green,
    'SVT': Colors.teal,
    'Anglais': Colors.red,
    'Espagnol': Colors.pink,
  };

  // Subject abbreviation mapping
  final Map<String, String> _subjectAbbr = {
    'Mathématiques': 'MA',
    'Physique-Chimie': 'PC',
    'Français': 'FR',
    'Histoire-Géographie': 'HG',
    'SVT': 'SV',
    'Anglais': 'AN',
    'Espagnol': 'ES',
  };

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentController>(
      builder: (context, controller, child) {
        final allHomeworks = controller.homeworks;
        final pendingHomeworks = controller.getPendingHomeworks();
        final completedHomeworks = controller.getCompletedHomeworks();

        // Filter homeworks based on selected filter
        List<Homework> filteredHomeworks;
        switch (_selectedFilter) {
          case 'À faire':
            filteredHomeworks = pendingHomeworks;
            break;
          case 'Rendus':
            filteredHomeworks = completedHomeworks;
            break;
          default:
            filteredHomeworks = allHomeworks;
        }

        // Calculate stats
        final totalCount = allHomeworks.length;
        final pendingCount = pendingHomeworks.length;
        final completedCount = completedHomeworks.length;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Devoirs',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // ===== STATISTICS ROW =====
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Total
                    Expanded(
                      child: _buildStatCard(
                        value: totalCount.toString(),
                        label: 'Total',
                        color: Colors.grey[800]!,
                        bgColor: Colors.grey[100]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // À faire
                    Expanded(
                      child: _buildStatCard(
                        value: pendingCount.toString(),
                        label: 'À faire',
                        color: Colors.orange[700]!,
                        bgColor: Colors.orange[50]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rendus
                    Expanded(
                      child: _buildStatCard(
                        value: completedCount.toString(),
                        label: 'Rendus',
                        color: Colors.green[700]!,
                        bgColor: Colors.green[50]!,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== FILTER TABS =====
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = filter == _selectedFilter;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: isSelected 
                                ? null 
                                : Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            filter,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ===== HOMEWORK LIST =====
              Expanded(
                child: filteredHomeworks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.green[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun devoir trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredHomeworks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final homework = filteredHomeworks[index];
                          return _buildHomeworkCard(homework);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // TODO: Ajouter un nouveau devoir
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Homework homework) {
    final dateStr = _formatDate(homework.dueDate.toDate());
    final isLate = homework.dueDate.toDate().isBefore(DateTime.now()) && !homework.isCompleted;
    final subjectColor = _subjectColors[homework.subject] ?? Colors.blue;
    final subjectAbbr = _subjectAbbr[homework.subject] ?? homework.subject.substring(0, 2).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: subjectColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                subjectAbbr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homework.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  homework.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Status badge
                    if (isLate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'En retard',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Date
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}