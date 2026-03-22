import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_user_page.dart';
import '../../notifications/notifications_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

enum _UsersFilter { all, students, teachers }

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  _UsersFilter _filter = _UsersFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Utilisateurs',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('utilisateurs')
            .orderBy('createdAt', descending: true)
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
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final users = docs.map(_AdminUser.fromDoc).toList(growable: false);

          final totalCount = users.length;
          final studentsCount = users.where((u) => u.isStudent).length;
          final teachersCount = users.where((u) => u.isTeacher).length;

          final query = _searchController.text.trim().toLowerCase();
          final filtered = users
              .where((u) {
                final roleOk = switch (_filter) {
                  _UsersFilter.all => true,
                  _UsersFilter.students => u.isStudent,
                  _UsersFilter.teachers => u.isTeacher,
                };

                if (!roleOk) return false;
                if (query.isEmpty) return true;

                final haystack = '${u.displayName} ${u.email} ${u.roleLabel}'
                    .toLowerCase();
                return haystack.contains(query);
              })
              .toList(growable: false);

          return Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Rechercher...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _AddButton(
                      onTap: () async {
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const AddUserPage(),
                          ),
                        );
                        if (created == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Utilisateur ajouté'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tous',
                      count: totalCount,
                      selected: _filter == _UsersFilter.all,
                      onTap: () => setState(() => _filter = _UsersFilter.all),
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Élèves',
                      count: studentsCount,
                      selected: _filter == _UsersFilter.students,
                      onTap: () =>
                          setState(() => _filter = _UsersFilter.students),
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Profs',
                      count: teachersCount,
                      selected: _filter == _UsersFilter.teachers,
                      onTap: () =>
                          setState(() => _filter = _UsersFilter.teachers),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const _CenteredMessage(
                        icon: Icons.inbox_outlined,
                        title: 'Aucun résultat',
                        message: 'Aucun utilisateur ne correspond.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          return _UserTile(user: user);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A00),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFFF7A00) : const Color(0xFFF1F3F5);
    final fg = selected ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: fg),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.22) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: selected ? Colors.white : const Color(0xFF7A7A7A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final _AdminUser user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final badge = _RoleBadgeData.fromRole(user.role);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.grey[700],
            child: const Icon(Icons.person, size: 22),
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
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RoleBadge(data: badge),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.mail_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[500]),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _RoleBadgeData {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _RoleBadgeData({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  factory _RoleBadgeData.fromRole(String role) {
    switch (role) {
      case 'eleve':
        return const _RoleBadgeData(
          label: 'Élève',
          icon: Icons.school_outlined,
          bg: Color(0xFFE8F0FE),
          fg: Color(0xFF2B56F5),
        );
      case 'enseignant':
      case 'professeur':
        return const _RoleBadgeData(
          label: 'Professeur',
          icon: Icons.person_outline,
          bg: Color(0xFFF4ECFF),
          fg: Color(0xFF8C45F7),
        );
      case 'parent':
        return const _RoleBadgeData(
          label: 'Parent',
          icon: Icons.people_outline,
          bg: Color(0xFFE9F7EE),
          fg: Color(0xFF34A853),
        );
      case 'admin':
        return const _RoleBadgeData(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          bg: Color(0xFFFFF3E0),
          fg: Color(0xFFFB8C00),
        );
      default:
        return const _RoleBadgeData(
          label: 'Utilisateur',
          icon: Icons.person_outline,
          bg: Color(0xFFF1F3F5),
          fg: Color(0xFF7A7A7A),
        );
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final _RoleBadgeData data;

  const _RoleBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: data.fg),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              color: data.fg,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUser {
  final String id;
  final String email;
  final String role;
  final String displayName;

  const _AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
  });

  bool get isStudent => role == 'eleve' || role == 'student';

  bool get isTeacher =>
      role == 'enseignant' || role == 'professeur' || role == 'teacher';

  String get roleLabel => _RoleBadgeData.fromRole(role).label;

  static _AdminUser fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final email = (data['email'] as String?) ?? '';
    final role = (data['role'] as String?) ?? '';

    final firstName = (data['prenom'] as String?)?.trim();
    final lastName = (data['nom'] as String?)?.trim();
    final displayName = (data['displayName'] as String?)?.trim();

    final composed = [
      if (lastName != null && lastName.isNotEmpty) lastName,
      if (firstName != null && firstName.isNotEmpty) firstName,
    ].join(' ');

    return _AdminUser(
      id: doc.id,
      email: email,
      role: role,
      displayName: (displayName?.isNotEmpty ?? false)
          ? displayName!
          : (composed.isNotEmpty
                ? composed
                : (email.isNotEmpty ? email : doc.id)),
    );
  }
}
