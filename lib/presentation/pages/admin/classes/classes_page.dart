import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../timetable/timetable_page.dart';

class AdminClassesPage extends StatelessWidget {
  const AdminClassesPage({super.key});

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
          'Classes',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Ajouter une classe',
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () => _showAddClassDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, classesSnapshot) {
          if (classesSnapshot.hasError) {
            return _CenteredMessage(
              icon: Icons.error_outline,
              title: 'Erreur',
              message: classesSnapshot.error.toString(),
            );
          }

          if (!classesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final storedClasses = <String>{
            for (final d in classesSnapshot.data!.docs)
              ((d.data()['name'] ?? d.id) ?? '').toString().trim(),
          }..removeWhere((c) => c.isEmpty);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

              final users = usersSnapshot.data!.docs
                  .map((d) => d.data())
                  .toList();

              final Map<String, int> classToStudentCount = {};
              for (final u in users) {
                final rawRole = (u['role'] ?? u['type'] ?? '')
                    .toString()
                    .toLowerCase();
                final isStudent =
                    rawRole.contains('eleve') ||
                    rawRole.contains('élève') ||
                    rawRole == 'student';
                if (!isStudent) continue;

                final classe = (u['classe'] ?? u['class'] ?? '')
                    .toString()
                    .trim();
                if (classe.isEmpty) continue;

                classToStudentCount.update(
                  classe,
                  (v) => v + 1,
                  ifAbsent: () => 1,
                );
              }

              final allClassNames = <String>{
                ...storedClasses,
                ...classToStudentCount.keys,
              };
              final classEntries =
                  allClassNames
                      .map((c) => MapEntry(c, classToStudentCount[c] ?? 0))
                      .toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

              if (classEntries.isEmpty) {
                return const _CenteredMessage(
                  icon: Icons.apartment_outlined,
                  title: 'Aucune classe',
                  message: "Ajoutez une classe avec le bouton +.",
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemBuilder: (context, index) {
                  final entry = classEntries[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminTimetablePage(initialClass: entry.key),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
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
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance_outlined,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.value} élèves',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: classEntries.length,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddClassDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ajouter une classe'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Ex: 2nde A'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createClass(ctx, controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _createClass(ctx, controller.text),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createClass(BuildContext context, String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;

    await FirebaseFirestore.instance.collection('classes').doc(name).set({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (context.mounted) {
      Navigator.of(context).pop();
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
