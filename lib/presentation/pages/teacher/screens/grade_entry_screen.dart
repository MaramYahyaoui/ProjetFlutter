import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../controllers/teacher_controller.dart';
import '../../../../models/grade_entry_model.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TeacherController _controller;

  // Form fields
  String? _selectedClass;
  String? _selectedMatiere;
  String? _selectedStudentId;
  String? _selectedEvaluationType;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _coefficientController =
      TextEditingController(text: '1');
  final TextEditingController _commentController = TextEditingController();

  List<String> _students = [];

  final List<String> _evaluationTypes = [
    'Contrôle',
    'Devoir',
    'Examen',
    'Quiz',
    'Participation',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('role', isEqualTo: 'eleve')
          .get();

      setState(() {
        _students = snapshot.docs
            .map((doc) => doc.id)
            .toList();
      });
    } catch (e) {
      debugPrint('❌ Erreur loadStudents: $e');
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _coefficientController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisie des Notes'),
        elevation: 0,
      ),
      body: Consumer<TeacherController>(
        builder: (context, controller, _) {
          _controller = controller;

          if (controller.classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormSection(
                    'Informations de l\'évaluation',
                    [
                      _buildClassDropdown(controller),
                      const SizedBox(height: 16),
                      _buildMatiereDropdown(controller),
                      const SizedBox(height: 16),
                      _buildStudentDropdown(),
                      const SizedBox(height: 16),
                      _buildEvaluationTypeDropdown(),
                      const SizedBox(height: 16),
                      _buildDatePicker(context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFormSection(
                    'Résultats',
                    [
                      _buildNoteField(),
                      const SizedBox(height: 16),
                      _buildCoefficientField(),
                      const SizedBox(height: 16),
                      _buildCommentField(),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.check),
                      label: const Text('Enregistrer la note'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildClassDropdown(TeacherController controller) {
    return DropdownButtonFormField<String>(
      value: _selectedClass,
      decoration: InputDecoration(
        labelText: 'Classe',
        prefixIcon: const Icon(Icons.school),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: controller.classes
          .map((className) => DropdownMenuItem(
                value: className,
                child: Text(className),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedClass = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sélectionnez une classe';
        }
        return null;
      },
    );
  }

  Widget _buildMatiereDropdown(TeacherController controller) {
    return DropdownButtonFormField<String>(
      value: _selectedMatiere,
      decoration: InputDecoration(
        labelText: 'Matière',
        prefixIcon: const Icon(Icons.subject),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: controller.subjects
          .map((subject) => DropdownMenuItem(
                value: subject,
                child: Text(subject),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedMatiere = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sélectionnez une matière';
        }
        return null;
      },
    );
  }

  Widget _buildStudentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStudentId,
      decoration: InputDecoration(
        labelText: 'Élève',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: _students
          .map((id) => DropdownMenuItem(
                value: id,
                child: Text('Élève $id'),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedStudentId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sélectionnez un élève';
        }
        return null;
      },
    );
  }

  Widget _buildEvaluationTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEvaluationType,
      decoration: InputDecoration(
        labelText: 'Type d\'évaluation',
        prefixIcon: const Icon(Icons.assignment),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: _evaluationTypes
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedEvaluationType = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sélectionnez un type';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de l\'évaluation',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Note (0-20)',
        prefixIcon: const Icon(Icons.grade),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixText: '/20',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Entrez une note';
        }
        final note = double.tryParse(value);
        if (note == null || note < 0 || note > 20) {
          return 'La note doit être entre 0 et 20';
        }
        return null;
      },
    );
  }

  Widget _buildCoefficientField() {
    return TextFormField(
      controller: _coefficientController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Coefficient',
        prefixIcon: const Icon(Icons.scale),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Entrez un coefficient';
        }
        final coeff = double.tryParse(value);
        if (coeff == null || coeff <= 0) {
          return 'Le coefficient doit être supérieur à 0';
        }
        return null;
      },
    );
  }

  Widget _buildCommentField() {
    return TextFormField(
      controller: _commentController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Commentaires (facultatif)',
        prefixIcon: const Icon(Icons.comment),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final gradeEntry = GradeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profId: _controller.uid,
      eleveId: _selectedStudentId!,
      matiere: _selectedMatiere!,
      type: _selectedEvaluationType!,
      note: double.parse(_noteController.text),
      coefficient: double.parse(_coefficientController.text),
      date: _selectedDate,
      commentaire: _commentController.text.isEmpty ? null : _commentController.text,
    );

    final success = await _controller.addGradeEntry(gradeEntry);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _noteController.clear();
      _coefficientController.text = '1';
      _commentController.clear();
      _selectedClass = null;
      _selectedMatiere = null;
      _selectedStudentId = null;
      _selectedEvaluationType = null;
      _selectedDate = DateTime.now();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
