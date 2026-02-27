import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/student_controller.dart';
import '../../../../models/note_model.dart';
import '../widgets/note_card.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _selectedFilter = 'Toutes';

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudentController>(context);
    final allNotes = controller.notes;

    final subjects =
        allNotes.map((note) => note.matiere).toSet().toList()..sort();

    final filters = ['Toutes', ...subjects];

    final filteredNotes = _selectedFilter == 'Toutes'
        ? allNotes
        : allNotes
            .where((note) => note.matiere == _selectedFilter)
            .toList();

    double average = 0;
    if (filteredNotes.isNotEmpty) {
      final sum = filteredNotes.fold<double>(
        0,
        (sum, note) => sum + note.note,
      );
      average = sum / filteredNotes.length;
    }

    return Scaffold(
      body: Column(
        children: [

          // ===== STATISTICS =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Moyenne',
                  average.toStringAsFixed(1),
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildStatItem(
                  'Notes',
                  filteredNotes.length.toString(),
                  Icons.grade,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Matières',
                  subjects.length.toString(),
                  Icons.book,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // ===== FILTER =====
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final subject = filters[index];
                final isSelected = subject == _selectedFilter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = subject;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        subject,
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
            child: filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grade_outlined,
                            size: 64,
                            color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune note disponible',
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
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      return NoteCard(
                          note: filteredNotes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
