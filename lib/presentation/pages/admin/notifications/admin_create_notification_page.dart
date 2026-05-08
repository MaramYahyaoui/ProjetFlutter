import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminCreateNotificationPage extends StatefulWidget {
  const AdminCreateNotificationPage({super.key});

  @override
  State<AdminCreateNotificationPage> createState() =>
      _AdminCreateNotificationPageState();
}

enum _AudienceType { all, students, teachers, parents, specificUser }

class _AdminCreateNotificationPageState
    extends State<AdminCreateNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _isSending = false;
  _AudienceType _audienceType = _AudienceType.all;
  String? _selectedUserId;
  List<_UserRecipient> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .get();

      final users =
          snapshot.docs
              .map((doc) => _UserRecipient.fromDoc(doc))
              .where((u) => u.role != 'admin')
              .toList()
            ..sort(
              (a, b) => a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
            );

      if (!mounted) return;
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement utilisateurs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une notification')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAudienceSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Le message est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendNotification,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSending ? 'Envoi...' : 'Envoyer la notification',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceSection() {
    final specificUsers = _allUsers;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destinataires',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_AudienceType>(
            value: _audienceType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: _AudienceType.all,
                child: Text('Tous (élèves, enseignants, parents)'),
              ),
              DropdownMenuItem(
                value: _AudienceType.students,
                child: Text('Tous les élèves'),
              ),
              DropdownMenuItem(
                value: _AudienceType.teachers,
                child: Text('Tous les enseignants'),
              ),
              DropdownMenuItem(
                value: _AudienceType.parents,
                child: Text('Tous les parents'),
              ),
              DropdownMenuItem(
                value: _AudienceType.specificUser,
                child: Text('Utilisateur spécifique'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _audienceType = value ?? _AudienceType.all;
                if (_audienceType != _AudienceType.specificUser) {
                  _selectedUserId = null;
                }
              });
            },
          ),
          if (_audienceType == _AudienceType.specificUser) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedUserId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
                labelText: 'Choisir un utilisateur',
              ),
              items: specificUsers
                  .map(
                    (u) => DropdownMenuItem<String>(
                      value: u.id,
                      child: Text('${u.displayName} (${u.roleLabel})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedUserId = value),
              validator: (value) {
                if (_audienceType == _AudienceType.specificUser &&
                    (value == null || value.isEmpty)) {
                  return 'Sélectionnez un utilisateur';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final recipients = _resolveRecipients();
      if (recipients.isEmpty) {
        throw Exception('Aucun destinataire trouvé');
      }

      final currentAdminId = FirebaseAuth.instance.currentUser?.uid;
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      final batch = FirebaseFirestore.instance.batch();
      for (final recipientId in recipients) {
        final docRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc();
        batch.set(docRef, {
          'userId': recipientId,
          'title': title,
          'body': body,
          'type': 'admin_announcement',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': currentAdminId,
          'source': 'admin_console',
          'audience': _audienceType.name,
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification envoyée à ${recipients.length} destinataire(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur envoi notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Set<String> _resolveRecipients() {
    if (_audienceType == _AudienceType.specificUser) {
      final id = (_selectedUserId ?? '').trim();
      if (id.isEmpty) return <String>{};
      return <String>{id};
    }

    final users = _allUsers.where((u) {
      switch (_audienceType) {
        case _AudienceType.all:
          return u.role != 'admin';
        case _AudienceType.students:
          return _isStudentRole(u.role);
        case _AudienceType.teachers:
          return _isTeacherRole(u.role);
        case _AudienceType.parents:
          return _isParentRole(u.role);
        case _AudienceType.specificUser:
          return false;
      }
    });

    return users.map((u) => u.id).toSet();
  }

  bool _isStudentRole(String role) => role == 'eleve' || role == 'student';

  bool _isTeacherRole(String role) =>
      role == 'enseignant' || role == 'professeur' || role == 'teacher';

  bool _isParentRole(String role) => role == 'parent';
}

class _UserRecipient {
  final String id;
  final String displayName;
  final String role;

  const _UserRecipient({
    required this.id,
    required this.displayName,
    required this.role,
  });

  String get roleLabel {
    if (role == 'eleve' || role == 'student') return 'Élève';
    if (role == 'enseignant' || role == 'professeur' || role == 'teacher') {
      return 'Enseignant';
    }
    if (role == 'parent') return 'Parent';
    if (role == 'admin') return 'Admin';
    return role;
  }

  factory _UserRecipient.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final displayName = (data['displayName'] as String?)?.trim();
    final name = (data['name'] as String?)?.trim();
    final firstName = (data['prenom'] as String?)?.trim();
    final lastName = (data['nom'] as String?)?.trim();

    final fullName = [
      firstName,
      lastName,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' ').trim();

    final resolvedName = (displayName?.isNotEmpty ?? false)
        ? displayName!
        : (name?.isNotEmpty ?? false)
        ? name!
        : fullName.isNotEmpty
        ? fullName
        : doc.id;

    return _UserRecipient(
      id: doc.id,
      displayName: resolvedName,
      role: (data['role'] as String?)?.trim().toLowerCase() ?? '',
    );
  }
}
