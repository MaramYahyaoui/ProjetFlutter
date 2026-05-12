import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/absence_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/emploi.dart';
import '../../../models/absence_model.dart';
import '../../../models/user_model.dart';

class AbsencesPage extends StatefulWidget {
  final String? studentId;
  final String? childName;

  const AbsencesPage({
    super.key,
    this.studentId,
    this.childName,
  });

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  late final AbsenceController _controller;

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _teacherIdController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _classroomController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController(
    text: '08:00',
  );
  final TextEditingController _endTimeController = TextEditingController(
    text: '10:00',
  );
  final TextEditingController _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _initialized = false;
  List<User> _allStudents = [];
  List<String> _classOptions = [];
  String? _selectedClass;
  String? _selectedStudentId;
  final Map<String, String> _studentNames = {};

  @override
  void initState() {
    super.initState();
    _controller = AbsenceController(firebaseService: FirebaseService());
    _controller.addListener(_onControllerChanged);

    if (widget.studentId != null) {
      _studentIdController.text = widget.studentId!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadInitialData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _studentIdController.dispose();
    _teacherIdController.dispose();
    _subjectController.dispose();
    _classroomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AbsencesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId && widget.studentId != null) {
      _studentIdController.text = widget.studentId!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAbsences());
    }
    if (oldWidget.childName != widget.childName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      // After controller updates, ensure we have student names for visible absences
      _fetchNamesFor(_visibleAbsences);
    }
  }

  Future<void> _fetchNamesFor(List<Absence> absences) async {
    final missing = <String>{};
    for (final a in absences) {
      final id = a.studentId;
      if (id.isEmpty) continue;
      if (!_studentNames.containsKey(id)) missing.add(id);
    }
    if (missing.isEmpty) return;

    final firebase = FirebaseService();
    for (final id in missing) {
      try {
        final user = await firebase.getUserProfile(id);
        if (user != null) {
          _studentNames[id] = user.fullName;
        }
      } catch (_) {
        // ignore individual failures
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    final authUser = context.read<AuthController>().user;
    if (authUser == null) return;

    if (authUser.role == UserRoles.teacher) {
      await _loadStudentsForTeacherForm();
    }

    switch (authUser.role) {
      case UserRoles.teacher:
        await _controller.loadTeacherAbsences(authUser.id);
        break;
      case UserRoles.admin:
        await _controller.loadAllAbsences();
        break;
      case UserRoles.student:
        // Élève connecté : charger ses absences
        await _controller.loadStudentAbsences(authUser.id);
        break;
      case UserRoles.parent:
        // Parent : charger l'enfant sélectionné si fourni
        final studentId = widget.studentId ?? _studentIdController.text.trim();
        if (studentId.isNotEmpty) {
          await _controller.loadStudentAbsences(studentId);
        }
        break;
      default:
        final studentId = widget.studentId ?? _studentIdController.text.trim();
        if (studentId.isNotEmpty) {
          await _controller.loadStudentAbsences(studentId);
        }
        break;
    }
  }

  Future<void> _loadStudentsForTeacherForm() async {
    try {
      final firebaseService = FirebaseService();
      final users = await firebaseService.getUsersByRole(UserRoles.student);
      final students = users.where((u) => (u.classe ?? '').trim().isNotEmpty).toList();
      students.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      final classes = students
          .map((u) => (u.classe ?? '').trim())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;

      setState(() {
        _allStudents = students;
        _classOptions = classes;

        if (_selectedClass != null && !_classOptions.contains(_selectedClass)) {
          _selectedClass = null;
          _selectedStudentId = null;
          _studentIdController.clear();
          _classroomController.clear();
        }
      });
    } catch (_) {
      // Keep form usable even if student loading fails.
    }
  }

  List<User> get _studentsForSelectedClass {
    if ((_selectedClass ?? '').isEmpty) return const [];
    final classe = _selectedClass!.trim();
    final filtered = _allStudents
        .where((s) => (s.classe ?? '').trim() == classe)
        .toList();
    filtered.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return filtered;
  }

  void _onClassChanged(String? classe) {
    setState(() {
      _selectedClass = classe;
      _selectedStudentId = null;
      _studentIdController.clear();
      _classroomController.text = (classe ?? '').trim();
    });
  }

  void _onStudentChanged(String? studentId) {
    setState(() {
      _selectedStudentId = studentId;
      _studentIdController.text = studentId ?? '';
    });
  }

  Future<void> _loadAbsences() async {
    await _loadInitialData();
  }

  List<Absence> get _visibleAbsences {
    final authUser = context.read<AuthController>().user;
    if (authUser == null ||
        authUser.role == UserRoles.student ||
        authUser.role == UserRoles.parent) {
      return _controller.studentAbsences;
    }
    return _controller.absences;
  }

  String get _title {
    final authUser = context.read<AuthController>().user;
    switch (authUser?.role) {
      case UserRoles.teacher:
        return 'Absences élèves';
      case UserRoles.parent:
        return 'Absences de l\'enfant';
      case UserRoles.admin:
        return 'Absences professeurs';
      default:
        return 'Mes absences';
    }
  }

  String get _subtitle {
    final authUser = context.read<AuthController>().user;
    switch (authUser?.role) {
      case UserRoles.teacher:
        return 'Saisie rapide et historique des absences signalées.';
      case UserRoles.admin:
        return 'Consultation des absences enregistrées par les professeurs.';
      case UserRoles.parent:
        return 'Suivi en temps réel et notifications dans l\'app.';
      default:
        return 'Historique personnel des absences et retards.';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _createAbsence() async {
    final studentId = _studentIdController.text.trim();
    final subject = _subjectController.text.trim();
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (studentId.isEmpty || subject.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      _showMessage('Renseigne l\'élève, la matière et les horaires.');
      return;
    }

    await _controller.createAbsenceForStudent(
      studentId: studentId,
      subject: subject,
      date: _selectedDate,
      startTime: startTime,
      endTime: endTime,
    );

    if (_controller.error == null) {
      _showMessage('Absence créée avec succès.');
      await _reloadVisibleAbsences();
    } else {
      _showMessage(_controller.error ?? 'Erreur inconnue');
    }
  }

  Future<void> _createAutoAbsence() async {
    final studentId = _studentIdController.text.trim();
    final subject = _subjectController.text.trim();
    final classroom = _classroomController.text.trim();
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (studentId.isEmpty || subject.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      _showMessage('Renseigne l\'élève, la matière et les horaires.');
      return;
    }

    final schedule = Schedule(
      id: '${studentId}_${_selectedDate.millisecondsSinceEpoch}',
      subject: subject,
      classroom: classroom,
      dayOfWeek: _selectedDate.weekday,
      startTime: startTime,
      endTime: endTime,
      type: 'eleve',
      ownerId: studentId,
    );

    await _controller.createAbsenceFromSchedule(
      studentId: studentId,
      schedule: schedule,
      date: _selectedDate,
    );

    if (_controller.error == null) {
      _showMessage('Absence créée à partir de l\'horaire.');
      await _reloadVisibleAbsences();
    } else {
      _showMessage(_controller.error ?? 'Erreur inconnue');
    }
  }

  Future<void> _loadTeacherAbsences() async {
    final teacherId = _teacherIdController.text.trim();
    if (teacherId.isEmpty) {
      _showMessage('Saisis l\'ID du professeur à consulter.');
      return;
    }

    await _controller.loadTeacherAbsences(teacherId);
  }

  Future<void> _reloadVisibleAbsences() async {
    final authUser = context.read<AuthController>().user;
    if (authUser == null) return;

    switch (authUser.role) {
      case UserRoles.teacher:
        await _controller.loadTeacherAbsences(authUser.id);
        break;
      case UserRoles.admin:
        await _controller.loadAllAbsences();
        break;
      default:
        final studentId = _studentIdController.text.trim();
        if (studentId.isNotEmpty) {
          await _controller.loadStudentAbsences(studentId);
        }
        break;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthController>().user;
    final absences = _visibleAbsences;
    final stats = _controller.getAbsenceStats(absences);
    final role = authUser?.role;
    final displayLabel = role == UserRoles.parent &&
        (widget.childName ?? '').trim().isNotEmpty
      ? widget.childName!.trim()
      : widget.studentId ?? authUser?.id ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadVisibleAbsences,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            _HeaderCard(
              title: _title,
              subtitle: _subtitle,
              label: displayLabel,
              role: role ?? UserRoles.student,
            ),
            const SizedBox(height: 16),
            _StatsGrid(stats: stats),
            const SizedBox(height: 16),
            if (role == UserRoles.teacher) ...[
              _TeacherFormCard(
                subjectController: _subjectController,
                classroomController: _classroomController,
                startTimeController: _startTimeController,
                endTimeController: _endTimeController,
                selectedDate: _selectedDate,
                selectedClass: _selectedClass,
                classOptions: _classOptions,
                selectedStudentId: _selectedStudentId,
                studentsForClass: _studentsForSelectedClass,
                onClassChanged: _onClassChanged,
                onStudentChanged: _onStudentChanged,
                onPickDate: _pickDate,
                onCreateAbsence: _createAbsence,
                onCreateAutoAbsence: _createAutoAbsence,
                isLoading: _controller.isLoading,
              ),
              const SizedBox(height: 16),
            ],
            if (role == UserRoles.admin) ...[
              _AdminFilterCard(
                teacherIdController: _teacherIdController,
                onLoad: _loadTeacherAbsences,
                isLoading: _controller.isLoading,
              ),
              const SizedBox(height: 16),
            ],
            if (role == UserRoles.parent) ...[
              _ParentNoticeCard(childName: widget.childName),
              const SizedBox(height: 16),
            ],
            _AbsenceListCard(
              absences: absences,
              isLoading: _controller.isLoading,
              role: role ?? UserRoles.student,
              studentNames: _studentNames,
            ),
            if (_controller.error != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: _controller.error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String label;
  final String role;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (role) {
      UserRoles.teacher => [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
      UserRoles.parent => [const Color(0xFF0F9D58), const Color(0xFF0B7A43)],
      UserRoles.admin => [const Color(0xFFEA580C), const Color(0xFFB45309)],
      _ => [const Color(0xFF4F46E5), const Color(0xFF2563EB)],
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label.isEmpty ? 'Aucun contexte sélectionné' : label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total',
            value: stats['total']?.toString() ?? '0',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Absent',
            value: stats['absent']?.toString() ?? '0',
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Justifié',
            value: stats['justified']?.toString() ?? '0',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Retard',
            value: stats['late']?.toString() ?? '0',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherFormCard extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController classroomController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final DateTime selectedDate;
  final String? selectedClass;
  final List<String> classOptions;
  final String? selectedStudentId;
  final List<User> studentsForClass;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onStudentChanged;
  final VoidCallback onPickDate;
  final VoidCallback onCreateAbsence;
  final VoidCallback onCreateAutoAbsence;
  final bool isLoading;

  const _TeacherFormCard({
    required this.subjectController,
    required this.classroomController,
    required this.startTimeController,
    required this.endTimeController,
    required this.selectedDate,
    required this.selectedClass,
    required this.classOptions,
    required this.selectedStudentId,
    required this.studentsForClass,
    required this.onClassChanged,
    required this.onStudentChanged,
    required this.onPickDate,
    required this.onCreateAbsence,
    required this.onCreateAutoAbsence,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Saisie d\'absence',
      icon: Icons.edit_calendar_rounded,
      child: Column(
        children: [
          _FieldRow(
            child: DropdownButtonFormField<String>(
              value: selectedClass,
              items: classOptions
                  .map(
                    (classe) => DropdownMenuItem<String>(
                      value: classe,
                      child: Text(classe),
                    ),
                  )
                  .toList(growable: false),
              onChanged: isLoading ? null : onClassChanged,
              decoration: const InputDecoration(
                labelText: 'Classe',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldRow(
            child: DropdownButtonFormField<String>(
              value: selectedStudentId,
              items: studentsForClass
                  .map(
                    (student) => DropdownMenuItem<String>(
                      value: student.id,
                      child: Text(student.fullName, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (isLoading || selectedClass == null) ? null : onStudentChanged,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'élève',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldRow(
            child: TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Matière',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldRow(
            child: TextField(
              controller: classroomController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Salle / classe',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Début',
                    hintText: '08:00',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Fin',
                    hintText: '10:00',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Date sélectionnée : ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onCreateAbsence,
                  icon: const Icon(Icons.person_off_rounded),
                  label: const Text('Créer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onCreateAutoAbsence,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Depuis horaire'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminFilterCard extends StatelessWidget {
  final TextEditingController teacherIdController;
  final VoidCallback onLoad;
  final bool isLoading;

  const _AdminFilterCard({
    required this.teacherIdController,
    required this.onLoad,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Filtrer un professeur',
      icon: Icons.manage_search_rounded,
      child: Column(
        children: [
          TextField(
            controller: teacherIdController,
            decoration: const InputDecoration(
              labelText: 'ID professeur',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onLoad,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Charger les absences'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentNoticeCard extends StatelessWidget {
  final String? childName;

  const _ParentNoticeCard({this.childName});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Notifications parent',
      icon: Icons.notifications_active_rounded,
      child: Text(
        childName == null || childName!.trim().isEmpty
            ? 'Les notifications de l\'app remontent les nouvelles absences en temps réel.'
            : 'Tu recevras les notifications pour ${childName!.trim()} dès qu\'une absence est ajoutée ou justifiée.',
        style: const TextStyle(height: 1.4),
      ),
    );
  }
}

class _AbsenceListCard extends StatelessWidget {
  final List<Absence> absences;
  final bool isLoading;
  final String role;
  final Map<String, String> studentNames;

  const _AbsenceListCard({
    required this.absences,
    required this.isLoading,
    required this.role,
    required this.studentNames,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Historique',
      icon: Icons.list_alt_rounded,
      child: isLoading && absences.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          : absences.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: _EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'Aucune absence',
                    message: 'Aucun enregistrement disponible pour le moment.',
                  ),
                )
              : Column(
                  children: [
                    for (final absence in absences.take(12)) ...[
                      _AbsenceTile(absence: absence, role: role, studentNames: studentNames),
                      if (absence != absences.take(12).last)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
    );
  }
}

class _AbsenceTile extends StatelessWidget {
  final Absence absence;
  final String role;
  final Map<String, String> studentNames;

  const _AbsenceTile({required this.absence, required this.role, required this.studentNames});

  @override
  Widget build(BuildContext context) {
    final color = switch (absence.status) {
      'justified' => const Color(0xFF10B981),
      'late' => const Color(0xFFF59E0B),
      _ => const Color(0xFFEF4444),
    };

    final statusLabel = switch (absence.status) {
      'justified' => 'Justifiée',
      'late' => 'Retard',
      _ => 'Absente',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        absence.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(label: statusLabel, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${absence.startTime} - ${absence.endTime} · ${absence.date.day.toString().padLeft(2, '0')}/${absence.date.month.toString().padLeft(2, '0')}/${absence.date.year}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Élève: ${studentNames[absence.studentId] ?? absence.studentId}${absence.scheduleId != null ? ' · Cours: ${absence.scheduleId}' : ''}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                if ((absence.reason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Motif: ${absence.reason}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFB91C1C)),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _CardShell({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final Widget child;

  const _FieldRow({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 36, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
