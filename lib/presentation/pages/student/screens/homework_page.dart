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
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentController>(
      builder: (context, controller, child) {
        final pendingHomeworks = controller.getPendingHomeworks();
        final completedHomeworks = controller.getCompletedHomeworks();

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête
              Text(
                'Devoirs à faire',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Devoirs en attente
              if (pendingHomeworks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tous les devoirs sont terminés!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...pendingHomeworks.map((homework) => _buildHomeworkCard(
                      homework,
                      controller,
                      isPending: true,
                    )),

              // Devoirs terminés
              if (completedHomeworks.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Devoirs terminés',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                ...completedHomeworks.map((homework) => _buildHomeworkCard(
                      homework,
                      controller,
                      isPending: false,
                    )),
              ],
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

  Widget _buildHomeworkCard(
    Homework homework,
    StudentController controller, {
    required bool isPending,
  }) {
    // Formater la date depuis Timestamp
    final dateStr = _formatDate(homework.dueDate.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? _getPriorityColor(homework.dueDate.toDate()).withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: homework.isCompleted,
                onChanged: (value) {
                  controller.toggleHomeworkStatus(homework.id);
                },
                activeColor: Colors.green,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        decoration: homework.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      homework.subject,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPending
                      ? _getPriorityColor(homework.dueDate.toDate())
                          .withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPending
                        ? _getPriorityColor(homework.dueDate.toDate())
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              homework.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // En retard
    } else if (difference <= 2) {
      return Colors.orange; // Urgent
    } else if (difference <= 7) {
      return Colors.amber; // Bientôt
    } else {
      return Colors.green; // Pas urgent
    }
  }
}
