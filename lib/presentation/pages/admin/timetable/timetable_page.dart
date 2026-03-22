import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminTimetablePage extends StatefulWidget {
  final String? initialClass;

  const AdminTimetablePage({super.key, this.initialClass});

  @override
  State<AdminTimetablePage> createState() => _AdminTimetablePageState();
}

class _AdminTimetablePageState extends State<AdminTimetablePage> {
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClass;
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _selectedClass == null ? null : _openAddCourseDialog,
            tooltip: 'Ajouter un cours',
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

          final usersDocs = usersSnapshot.data!.docs;
          final users = usersDocs.map((d) => d.data()).toList();

          final classes = <String>{};
          for (final u in users) {
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

          final selected = _selectedClass;

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'Classe',
                      style: TextStyle(
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
                            value: selected,
                            hint: const Text('Choisir une classe'),
                            items: classList
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
                                .toList(growable: false),
                            onChanged: (v) =>
                                setState(() => _selectedClass = v),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: selected == null
                    ? const _CenteredMessage(
                        icon: Icons.schedule_outlined,
                        title: 'Aucune classe',
                        message:
                            "Créez d'abord des élèves avec un champ 'classe'.",
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('emplois')
                            .where('classe', isEqualTo: selected)
                            .snapshots(),
                        builder: (context, coursesSnapshot) {
                          if (coursesSnapshot.hasError) {
                            return _CenteredMessage(
                              icon: Icons.error_outline,
                              title: 'Erreur',
                              message: coursesSnapshot.error.toString(),
                            );
                          }

                          if (!coursesSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = coursesSnapshot.data!.docs;
                          final items = docs
                              .map((d) => _EmploiLite.fromDoc(d))
                              .toList();

                          items.sort((a, b) {
                            final dayCmp = a.dayIndex.compareTo(b.dayIndex);
                            if (dayCmp != 0) return dayCmp;
                            return a.start.compareTo(b.start);
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final c = items[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
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
                                            c.matiere,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (c.professeur != null &&
                                              c.professeur!.trim().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                c.professeur!,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${c.jour} • ${c.heureDebut} - ${c.heureFin}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Salle: ${c.salle}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
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

  Future<void> _openAddCourseDialog() async {
    final classe = _selectedClass;
    if (classe == null) return;

    final messenger = ScaffoldMessenger.of(context);

    final jours = const [
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

    String? selectedTeacherName;

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ajouter un cours'),
            content: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('utilisateurs')
                  .get(),
              builder: (context, snapshot) {
                final allUsers = snapshot.data?.docs ?? const [];

                final teachers =
                    allUsers
                        .map((d) => _TeacherLite.fromDoc(d))
                        .where((t) => t.isTeacher)
                        .toList(growable: false)
                      ..sort((a, b) => a.displayName.compareTo(b.displayName));

                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return StatefulBuilder(
                  builder: (context, setInnerState) {
                    return SingleChildScrollView(
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
                            decoration: const InputDecoration(
                              labelText: 'Matière',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: salleController,
                            decoration: const InputDecoration(
                              labelText: 'Salle',
                            ),
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
                          DropdownButtonFormField<String>(
                            value: selectedTeacherName,
                            items: teachers
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t.displayName,
                                    child: Text(t.displayName),
                                  ),
                                )
                                .toList(growable: false),
                            decoration: const InputDecoration(
                              labelText: 'Enseignant',
                            ),
                            onChanged: (v) {
                              setInnerState(() => selectedTeacherName = v);
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Classe: $classe',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final dialogContext = context;
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
                  await FirebaseFirestore.instance.collection('emplois').add({
                    'classe': classe,
                    'jour_semaine': dayIndex,
                    'type': 'eleve',
                    'ownerId': '',
                    'creneaux': {
                      'debut': heureDebut,
                      'fin': heureFin,
                      'matiere': matiere,
                      'salle': salle,
                      if (selectedTeacherName != null)
                        'professeur': selectedTeacherName,
                    },
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;
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
  final String id;
  final int dayOfWeek;
  final String heureDebut;
  final String heureFin;
  final String matiere;
  final String salle;
  final String? professeur;

  const _EmploiLite({
    required this.id,
    required this.dayOfWeek,
    required this.heureDebut,
    required this.heureFin,
    required this.matiere,
    required this.salle,
    required this.professeur,
  });

  String get jour {
    switch (dayOfWeek) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return 'Jour';
    }
  }

  int get dayIndex => dayOfWeek;

  String get start => heureDebut;

  static int dayIndexFromLowerDay(String lower) {
    switch (lower.trim().toLowerCase()) {
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

  factory _EmploiLite.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final creneaux = data['creneaux'];
    final creneauxMap = creneaux is Map<String, dynamic> ? creneaux : null;

    final dayRaw = data['jour_semaine'] ?? data['jour_semain'] ?? 1;
    final dayOfWeek = dayRaw is int
        ? dayRaw
        : int.tryParse(dayRaw.toString()) ?? 1;

    final matiere = (creneauxMap?['matiere'] ?? data['matiere'] ?? '')
        .toString();
    final salle = (creneauxMap?['salle'] ?? data['salle'] ?? '').toString();
    final debut = (creneauxMap?['debut'] ?? data['debut'] ?? '08:00')
        .toString();
    final fin = (creneauxMap?['fin'] ?? data['fin'] ?? '10:00').toString();
    final professeur = (creneauxMap?['professeur'] ?? data['professeur'])
        ?.toString();

    return _EmploiLite(
      id: doc.id,
      dayOfWeek: dayOfWeek,
      heureDebut: debut,
      heureFin: fin,
      matiere: matiere,
      salle: salle,
      professeur: professeur,
    );
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
