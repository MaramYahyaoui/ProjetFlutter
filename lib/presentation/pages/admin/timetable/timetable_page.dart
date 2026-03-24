import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../models/emploi.dart';

enum _TimetableMode { classe, professeur }

class AdminTimetablePage extends StatefulWidget {
  final String? initialClass;

  const AdminTimetablePage({super.key, this.initialClass});

  @override
  State<AdminTimetablePage> createState() => _AdminTimetablePageState();
}

class _AdminTimetablePageState extends State<AdminTimetablePage> {
  _TimetableMode _mode = _TimetableMode.classe;
  String? _selectedClass;
  String? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClass;
  }

  @override
  Widget build(BuildContext context) {
    final addEnabled = _mode == _TimetableMode.classe
        ? _selectedClass != null
        : _selectedTeacherId != null;

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
          'Emploi du temps',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: addEnabled ? _openAddSlotDialog : null,
            tooltip: 'Ajouter un créneau',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            return const Center(child: CircularProgressIndicator());
          }

          final docs = usersSnapshot.data!.docs;
          final teacherNameById = <String, String>{
            for (final d in docs)
              d.id:
                  (d.data()['nom'] ??
                          d.data()['name'] ??
                          d.data()['displayName'] ??
                          d.id)
                      .toString(),
          };

          final teachers =
              docs
                  .map((d) => _TeacherLite.fromDoc(d))
                  .where((t) => t.isTeacher)
                  .toList(growable: false)
                ..sort((a, b) => a.displayName.compareTo(b.displayName));

          final classes = <String>{};
          for (final d in docs) {
            final u = d.data();
            final rawRole = (u['role'] ?? u['type'] ?? '')
                .toString()
                .toLowerCase();
            final isStudent =
                rawRole.contains('eleve') ||
                rawRole.contains('élève') ||
                rawRole == 'student';
            if (!isStudent) continue;

            final classe = (u['classe'] ?? u['class'] ?? '').toString().trim();
            if (classe.isEmpty) continue;
            classes.add(classe);
          }

          final classList = classes.toList()..sort();
          if (_selectedClass == null && classList.isNotEmpty) {
            _selectedClass = classList.first;
          }

          if (_selectedTeacherId == null && teachers.isNotEmpty) {
            _selectedTeacherId = teachers.first.id;
          }

          final selectionMissing = _mode == _TimetableMode.classe
              ? _selectedClass == null
              : _selectedTeacherId == null;

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Classe'),
                            selected: _mode == _TimetableMode.classe,
                            onSelected: (_) {
                              setState(() => _mode = _TimetableMode.classe);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Professeur'),
                            selected: _mode == _TimetableMode.professeur,
                            onSelected: (_) {
                              setState(() => _mode = _TimetableMode.professeur);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _mode == _TimetableMode.classe
                              ? 'Classe'
                              : 'Professeur',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _mode == _TimetableMode.classe
                                    ? _selectedClass
                                    : _selectedTeacherId,
                                hint: Text(
                                  _mode == _TimetableMode.classe
                                      ? 'Choisir une classe'
                                      : 'Choisir un professeur',
                                ),
                                items: (_mode == _TimetableMode.classe
                                    ? classList
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(
                                                c,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(growable: false)
                                    : teachers
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t.id,
                                              child: Text(
                                                t.displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(growable: false)),
                                onChanged: (v) {
                                  setState(() {
                                    if (_mode == _TimetableMode.classe) {
                                      _selectedClass = v;
                                    } else {
                                      _selectedTeacherId = v;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: selectionMissing
                    ? _CenteredMessage(
                        icon: Icons.schedule_outlined,
                        title: _mode == _TimetableMode.classe
                            ? 'Aucune classe'
                            : 'Aucun professeur',
                        message: _mode == _TimetableMode.classe
                            ? "Créez d'abord des élèves avec un champ 'classe'."
                            : "Créez d'abord des professeurs dans la collection 'utilisateurs'.",
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _mode == _TimetableMode.classe
                            ? FirebaseFirestore.instance
                                  .collection('emplois')
                                  .where('type', isEqualTo: 'eleve')
                                  .where('classe', isEqualTo: _selectedClass)
                                  .snapshots()
                            : FirebaseFirestore.instance
                                  .collection('emplois')
                                  .where('type', isEqualTo: 'professeur')
                                  .where(
                                    'ownerId',
                                    isEqualTo: _selectedTeacherId,
                                  )
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
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final items =
                              snapshot.data!.docs
                                  .map((d) => Schedule.fromFirestore(d))
                                  .toList(growable: false)
                                ..sort((a, b) {
                                  final dayCmp = a.dayOfWeek.compareTo(
                                    b.dayOfWeek,
                                  );
                                  if (dayCmp != 0) return dayCmp;
                                  return a.startTime.compareTo(b.startTime);
                                });

                          if (items.isEmpty) {
                            return const _CenteredMessage(
                              icon: Icons.schedule_outlined,
                              title: 'Aucun créneau',
                              message:
                                  'Ajoutez des créneaux pour construire cet emploi du temps.',
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final s = items[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(13),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.book_outlined,
                                        color: Color(0xFFFF7A00),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.subject,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${s.dayName} • ${s.startTime} - ${s.endTime}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Salle: ${s.classroom}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (_mode == _TimetableMode.classe &&
                                              (s.teacher ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                'Prof: ${s.teacher}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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

  Future<void> _openAddSlotDialog() async {
    final classe = _selectedClass;
    final teacherId = _selectedTeacherId;

    if (_mode == _TimetableMode.classe && classe == null) return;
    if (_mode == _TimetableMode.professeur && teacherId == null) return;

    final messenger = ScaffoldMessenger.of(context);

    const jours = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];

    String selectedJour = 'lundi';
    final heureDebutController = TextEditingController(text: '08:00');
    final heureFinController = TextEditingController(text: '09:30');
    final matiereController = TextEditingController();
    final salleController = TextEditingController(text: 'A101');

    String? selectedTeacherForClassId;

    final usersSnap = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .get();
    final teacherNameById = <String, String>{
      for (final d in usersSnap.docs)
        d.id:
            (d.data()['nom'] ??
                    d.data()['name'] ??
                    d.data()['displayName'] ??
                    d.id)
                .toString(),
    };
    final teachers =
        usersSnap.docs
            .map((d) => _TeacherLite.fromDoc(d))
            .where((t) => t.isTeacher)
            .toList(growable: false)
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setInnerState) {
              final professorName = teacherId == null
                  ? null
                  : (teacherNameById[teacherId] ?? teacherId);

              return AlertDialog(
                title: const Text('Ajouter un créneau'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            flex: 4,
                            child: Text(
                              'Jour',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedJour,
                              items: jours
                                  .map(
                                    (j) => DropdownMenuItem(
                                      value: j,
                                      child: Text(j),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (v) {
                                if (v == null) return;
                                setInnerState(() => selectedJour = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: matiereController,
                        decoration: const InputDecoration(labelText: 'Matière'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: salleController,
                        decoration: const InputDecoration(labelText: 'Salle'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: heureDebutController,
                              decoration: const InputDecoration(
                                labelText: 'Heure début',
                                hintText: '08:00',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: heureFinController,
                              decoration: const InputDecoration(
                                labelText: 'Heure fin',
                                hintText: '09:30',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _mode == _TimetableMode.classe
                              ? 'Classe: $classe'
                              : 'Professeur: $professorName',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_mode == _TimetableMode.classe)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedTeacherForClassId,
                            items: teachers
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(t.displayName),
                                  ),
                                )
                                .toList(growable: false),
                            decoration: const InputDecoration(
                              labelText: 'Enseignant (optionnel)',
                            ),
                            onChanged: (v) {
                              setInnerState(
                                () => selectedTeacherForClassId = v,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final matiere = matiereController.text.trim();
                      final salle = salleController.text.trim();
                      final heureDebut = heureDebutController.text.trim();
                      final heureFin = heureFinController.text.trim();

                      if (matiere.isEmpty ||
                          heureDebut.isEmpty ||
                          heureFin.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez remplir matière + heures.'),
                          ),
                        );
                        return;
                      }

                      final dayIndex = _EmploiLite.dayIndexFromLowerDay(
                        selectedJour,
                      );
                      final effectiveTeacherId =
                          _mode == _TimetableMode.professeur
                          ? teacherId!
                          : selectedTeacherForClassId;
                      final effectiveTeacherName = effectiveTeacherId == null
                          ? null
                          : teacherNameById[effectiveTeacherId];

                      await FirebaseFirestore.instance
                          .collection('emplois')
                          .add({
                            if (_mode == _TimetableMode.classe)
                              'classe': classe,
                            'jour_semaine': dayIndex,
                            'type': _mode == _TimetableMode.classe
                                ? 'eleve'
                                : 'professeur',
                            'ownerId': _mode == _TimetableMode.classe
                                ? ''
                                : teacherId,
                            if (_mode == _TimetableMode.professeur)
                              'professeurId': teacherId,
                            'creneaux': {
                              'debut': heureDebut,
                              'fin': heureFin,
                              'matiere': matiere,
                              'salle': salle,
                              if (effectiveTeacherName != null)
                                'professeur': effectiveTeacherName,
                            },
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Créneau ajouté.')),
                      );
                    },
                    child: const Text('Ajouter'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      heureDebutController.dispose();
      heureFinController.dispose();
      matiereController.dispose();
      salleController.dispose();
    }
  }
}

class _TeacherLite {
  final String id;
  final String displayName;
  final String role;

  const _TeacherLite({
    required this.id,
    required this.displayName,
    required this.role,
  });

  bool get isTeacher {
    final r = role.toLowerCase();
    return r.contains('prof') || r.contains('enseign') || r == 'teacher';
  }

  factory _TeacherLite.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final role = (data['role'] ?? data['type'] ?? '').toString();
    final displayName =
        (data['nom'] ?? data['name'] ?? data['displayName'] ?? doc.id)
            .toString();
    return _TeacherLite(id: doc.id, displayName: displayName, role: role);
  }
}

class _EmploiLite {
  static int dayIndexFromLowerDay(String day) {
    switch (day.toLowerCase()) {
      case 'lundi':
        return 1;
      case 'mardi':
        return 2;
      case 'mercredi':
        return 3;
      case 'jeudi':
        return 4;
      case 'vendredi':
        return 5;
      case 'samedi':
        return 6;
      case 'dimanche':
        return 7;
      default:
        return 1;
    }
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
            Icon(icon, size: 44, color: Colors.black38),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
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
