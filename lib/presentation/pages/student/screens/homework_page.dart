import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/student_controller.dart';
import '../../../../models/homework_model.dart';
import '../../notifications/notifications_page.dart';

class HomeworkPage extends StatefulWidget {
  final bool showBackButton;

  const HomeworkPage({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  String _selectedFilter = 'Tous';

  final List<String> _filters = ['Tous', 'À faire', 'Rendus'];

  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  String? _selectedMatiere;
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _attachmentFileName;
  PlatformFile? _selectedFile;

  // Subject list
  final List<String> _matieres = [
    'Mathématiques',
    'Physique-Chimie',
    'Français',
    'Histoire-Géographie',
    'SVT',
    'Anglais',
    'Espagnol',
  ];

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
        final authController = context.read<AuthController>();
        final canCreateHomework =
            authController.isTeacher || authController.isAdmin;
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
            automaticallyImplyLeading: widget.showBackButton,
            leading: widget.showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
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
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // ===== STATISTICS ROW =====
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final homework = filteredHomeworks[index];
                          return _buildHomeworkCard(homework);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: canCreateHomework
              ? FloatingActionButton(
                  onPressed: () => _showAddHomeworkForm(context),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
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
    final isLate =
        homework.dueDate.toDate().isBefore(DateTime.now()) &&
        !homework.isCompleted;
    final subjectColor = _subjectColors[homework.subject] ?? Colors.blue;
    final subjectAbbr =
        _subjectAbbr[homework.subject] ??
        homework.subject.substring(0, 2).toUpperCase();

    return InkWell(
      onTap: () => _showHomeworkDetails(context, homework),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
      ),
    );
  }

  void _showHomeworkDetails(BuildContext context, Homework homework) {
    final controller = context.read<StudentController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HomeworkDetailsSheet(
        controller: controller,
        homework: homework,
      ),
    );
  }


  void _showAddHomeworkForm(BuildContext context) {
    _selectedMatiere = null;
    _titreController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    _attachmentFileName = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddHomeworkForm(context),
    );
  }

  Widget _buildAddHomeworkForm(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Ajouter un devoir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Matière field
                    const Text(
                      'Matière',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMatiere,
                      decoration: InputDecoration(
                        hintText: 'Sélectionner la matière',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: _matieres.map((matiere) {
                        return DropdownMenuItem(
                          value: matiere,
                          child: Text(matiere),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMatiere = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner une matière';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Titre field
                    const Text(
                      'Titre',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titreController,
                      decoration: InputDecoration(
                        hintText: 'Entrer le titre du devoir',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un titre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description field
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Entrer la description du devoir',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date de rendu field
                    const Text(
                      'Date de rendu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 7),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                                  : 'Sélectionner la date de rendu',
                              style: TextStyle(
                                color: _selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pièce jointe field
                    const Text(
                      'Pièce jointe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickAttachment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _attachmentFileName ??
                                    'Ajouter une pièce jointe (PDF, Image)',
                                style: TextStyle(
                                  color: _attachmentFileName != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (_attachmentFileName != null)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _attachmentFileName = null;
                                    _selectedFile = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitHomework,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ajouter le devoir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitHomework() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de rendu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    try {
      final controller = context.read<StudentController>();

      // Save file metadata directly to Firestore (no upload to Firebase Storage)
      await controller.addHomework(
        matiere: _selectedMatiere!,
        titre: _titreController.text,
        description: _descriptionController.text,
        dateLimite: _selectedDate!,
        attachmentName: _selectedFile?.name,
        attachmentType: _selectedFile?.extension,
        attachmentSize: _selectedFile?.size,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Close form
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devoir ajouté avec succès'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.single;
          _attachmentFileName = _selectedFile!.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _HomeworkDetailsSheet extends StatefulWidget {
  final StudentController controller;
  final Homework homework;

  const _HomeworkDetailsSheet({
    required this.controller,
    required this.homework,
  });

  @override
  State<_HomeworkDetailsSheet> createState() => _HomeworkDetailsSheetState();
}

class _HomeworkDetailsSheetState extends State<_HomeworkDetailsSheet> {
  PlatformFile? _selectedFile;

  bool get _isLate {
    final due = widget.homework.dueDate.toDate();
    return DateTime.now().isAfter(due);
  }

  String _fileTypeLabel(String? nameOrExt) {
    final lower = (nameOrExt ?? '').toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : lower;
    switch (ext) {
      case 'zip':
      case 'rar':
      case '7z':
        return 'Archive compressée';
      case 'pdf':
        return 'PDF';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'Image';
      case 'doc':
      case 'docx':
        return 'Document';
      default:
        return 'Fichier';
    }
  }

  Future<void> _pickFile() async {
    if (_isLate) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'zip', 'rar', '7z', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.48;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            final isSubmitted = widget.homework.isCompleted;
            final submittedFile =
                controller.getHomeworkSubmissionFile(widget.homework.id);
            final submittedName = (submittedFile?['nom'] as String?)?.trim();
            final activeFileName =
                (_selectedFile?.name ?? submittedName ?? '').trim();

            final canSubmit =
                !_isLate && !isSubmitted && activeFileName.isNotEmpty;
            final canCancel = !_isLate && isSubmitted;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Vos devoirs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isSubmitted ? 'Remis' : 'Attribué',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSubmitted ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Add or show submission file
                  if (activeFileName.isEmpty) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isLate ? null : _pickFile,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter ou créer'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeFileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fileTypeLabel(activeFileName),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.insert_drive_file, color: Colors.blue[700]),
                          )
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: canCancel
                          ? () async {
                              await widget.controller.cancelHomeworkSubmission(
                                devoirId: widget.homework.id,
                              );
                              if (mounted) Navigator.pop(context);
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Annuler l'envoi",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSubmit
                          ? () async {
                              final file = _selectedFile;
                              final fichier = <String, dynamic>{
                                'nom': file?.name ?? activeFileName,
                                'url': '',
                                'type': file?.extension ?? '',
                                'taille': file?.size ?? 0,
                              };
                              await widget.controller.setHomeworkSubmission(
                                devoirId: widget.homework.id,
                                fichier: fichier,
                                estRendu: true,
                              );
                              if (mounted) Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Remettre',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),

                  const Spacer(),

                  if (_isLate)
                    Center(
                      child: Text(
                        'Le devoir ne peut pas être remis après la\n date limite',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

