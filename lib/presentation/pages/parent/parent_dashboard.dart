import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/student_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../core/services/firebase_service.dart';
import '../student/screens/notes_page.dart';
import '../student/screens/schedule_page.dart';
import '../messages/conversations_page.dart';
import '../../widgets/user_profile_image_picker.dart';
import '../../widgets/recent_messages_preview.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Connexion requise.')));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('role', isEqualTo: 'eleve')
          .where('parentsIds', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Espace Parent')),
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final children = snapshot.data!.docs
            .map((d) => _ParentChildSummary.fromDoc(d))
            .toList(growable: false);

        if (children.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Espace Parent')),
            body: const Center(
              child: Text(
                "Aucun enfant associé à ce compte.\n"
                "(Ajoute ton UID dans 'parentsIds' sur le document élève)",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final selectedChild = _resolveSelectedChild(children);

        return ChangeNotifierProvider<StudentController>(
          key: ValueKey<String>(selectedChild.id),
          create: (_) => StudentController(selectedChild.id)..init(),
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: _buildBody(selectedChild, children),
            bottomNavigationBar: _buildBottomNav(),
          ),
        );
      },
    );
  }

  _ParentChildSummary _resolveSelectedChild(
    List<_ParentChildSummary> children,
  ) {
    if (_selectedChildId == null ||
        !children.any((c) => c.id == _selectedChildId)) {
      final first = children.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedChildId = first.id);
      });
      return first;
    }

    return children.firstWhere((c) => c.id == _selectedChildId);
  }

  Widget _buildBody(
    _ParentChildSummary selectedChild,
    List<_ParentChildSummary> children,
  ) {
    return switch (_selectedIndex) {
      0 => _ParentHomeTab(
        selectedChild: selectedChild,
        children: children,
        onSelectChild: (id) => setState(() => _selectedChildId = id),
        onOpenNotes: () => setState(() => _selectedIndex = 1),
        onOpenSchedule: () => setState(() => _selectedIndex = 2),
        onOpenMessages: () => setState(() => _selectedIndex = 3),
      ),
      1 => const NotesPage(showBackButton: false),
      2 => const SchedulePage(),
      3 => const _ParentMessagesTab(),
      _ => _ParentMenuTab(
        selectedChild: selectedChild,
        children: children,
        onSelectChild: (id) => setState(() {
          _selectedChildId = id;
          _selectedIndex = 0;
        }),
      ),
    };
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', 0),
              _buildNavItem(Icons.grade_rounded, 'Notes', 1),
              _buildNavItem(Icons.calendar_today_rounded, 'Agenda', 2),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 'Messages', 3),
              _buildNavItem(Icons.menu_rounded, 'Menu', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF09C15C) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentHomeTab extends StatelessWidget {
  final _ParentChildSummary selectedChild;
  final List<_ParentChildSummary> children;
  final ValueChanged<String> onSelectChild;
  final VoidCallback onOpenNotes;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenMessages;

  const _ParentHomeTab({
    required this.selectedChild,
    required this.children,
    required this.onSelectChild,
    required this.onOpenNotes,
    required this.onOpenSchedule,
    required this.onOpenMessages,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();
    final currentUser = context.watch<AuthController>().user;
    final average = controller.getAverage();
    final pendingCount = controller.getPendingHomeworks().length;
    final recentNotes = [...controller.notes]
      ..sort((a, b) => b.date.compareTo(a.date));

    final visibleNotes = recentNotes.take(3).toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ParentHeaderCard(
              selectedChild: selectedChild,
              children: children,
              onSelectChild: onSelectChild,
            ),
            const SizedBox(height: 56),
            _ParentAlertCard(
              pendingCount: pendingCount,
              childName: selectedChild.displayName,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ParentStatCard(
                    label: 'Moyenne',
                    value: average.isNaN ? '-' : average.toStringAsFixed(1),
                    suffix: '/20',
                    hint: '+0.5',
                    accent: const Color(0xFF09C15C),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ParentStatCard(
                    label: 'Absences',
                    value: pendingCount.toString(),
                    hint: pendingCount > 0
                        ? '$pendingCount non justifiée'
                        : 'Aucune',
                    accent: const Color(0xFFFF6D3A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ParentStatCard(
                    label: 'Rang',
                    value: '${(average / 2).clamp(1, 20).round()}',
                    suffix: '/28',
                    hint: 'Top 40%',
                    accent: const Color(0xFF8B5CFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Contacter',
                    subtitle: 'Un professeur',
                    accent: const Color(0xFF2F6DF6),
                    onTap: onOpenMessages,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.event_note_outlined,
                    title: 'Vie Scolaire',
                    subtitle: 'Signaler',
                    accent: const Color(0xFF8E42FF),
                    onTap: onOpenMessages,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notes récentes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: onOpenNotes,
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      color: Color(0xFF09C15C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!controller.isLoading && visibleNotes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Aucune note récente. Utilise les onglets Notes / Agenda / Messages.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            if (!controller.isLoading && visibleNotes.isNotEmpty)
              ...visibleNotes.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentNoteTile(note: n),
                ),
              ),
            const SizedBox(height: 2),
            Center(
              child: TextButton(
                onPressed: onOpenNotes,
                child: const Text(
                  'Voir toutes les notes',
                  style: TextStyle(
                    color: Color(0xFF09C15C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (currentUser != null) ...[
              const SizedBox(height: 28),
              RecentMessagesPreview(
                currentUser: currentUser,
                onOpenAll: onOpenMessages,
                accentColor: const Color(0xFF09C15C),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParentHeaderCard extends StatelessWidget {
  final _ParentChildSummary selectedChild;
  final List<_ParentChildSummary> children;
  final ValueChanged<String> onSelectChild;

  const _ParentHeaderCard({
    required this.selectedChild,
    required this.children,
    required this.onSelectChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF09C15C),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bon retour,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Parent dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Center(
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 5,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: children.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final child = children[index];
                      final isActive = child.id == selectedChild.id;
                      return GestureDetector(
                        onTap: () => onSelectChild(child.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 170),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: isActive
                                    ? const Color(0xFF09C15C).withOpacity(0.18)
                                    : Colors.white.withOpacity(0.30),
                                child: Text(
                                  _initials(child.displayName),
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFF09C15C)
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                child.displayName.split(' ').first,
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF1F2937)
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: -40,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      _initials(selectedChild.displayName),
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedChild.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${selectedChild.id.substring(0, selectedChild.id.length > 8 ? 8 : selectedChild.id.length)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF09C15C),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                selectedChild.classe.isNotEmpty
                                    ? selectedChild.classe
                                    : 'Classe -',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Présent',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
          ),
        ],
      ),
    );
  }
}

class _ParentAlertCard extends StatelessWidget {
  final int pendingCount;
  final String childName;

  const _ParentAlertCard({required this.pendingCount, required this.childName});

  @override
  Widget build(BuildContext context) {
    final hasAlert = pendingCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasAlert ? const Color(0xFFFFF6ED) : const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAlert ? const Color(0xFFFFC99A) : const Color(0xFF96E2B0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: hasAlert
                  ? const Color(0xFFFFE4D1)
                  : const Color(0xFFD9F6E3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasAlert
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: hasAlert
                  ? const Color(0xFFFF6D3A)
                  : const Color(0xFF08A045),
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAlert ? 'Absence non justifiée' : 'Aucune alerte',
                  style: TextStyle(
                    color: hasAlert
                        ? const Color(0xFFCB4D1A)
                        : const Color(0xFF067D35),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAlert
                      ? '$childName a $pendingCount devoir(s) à suivre cette semaine.'
                      : '$childName n\'a aucune alerte aujourd\'hui.',
                  style: TextStyle(
                    color: hasAlert
                        ? const Color(0xFFD26A42)
                        : const Color(0xFF2F8F57),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.35,
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

class _ParentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String hint;
  final Color accent;

  const _ParentStatCard({
    required this.label,
    required this.value,
    this.suffix,
    required this.hint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 3),
                  child: Text(
                    suffix!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF0F2)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentNoteTile extends StatelessWidget {
  final dynamic note;

  const _RecentNoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final noteValue = (note.note as double).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _subjectColor(note.matiere).withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(note.matiere),
                style: TextStyle(
                  color: _subjectColor(note.matiere),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.matiere,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${note.type} • ${_formatDate(note.date)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              text: noteValue,
              style: const TextStyle(
                color: Color(0xFF09C15C),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text: '/20',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

String _initials(String text) {
  final parts = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) return '--';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatDate(DateTime d) {
  const days = ['', 'Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
  const months = [
    '',
    'Jan',
    'Fev',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Aou',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${days[d.weekday]} ${d.day} ${months[d.month]}';
}

Color _subjectColor(String matiere) {
  final key = matiere.trim().toLowerCase();
  if (key.contains('math')) return const Color(0xFF3B82F6);
  if (key.contains('phys') || key.contains('chim'))
    return const Color(0xFF8B5CF6);
  if (key.contains('hist') || key.contains('geo'))
    return const Color(0xFFF59E0B);
  if (key.contains('fran')) return const Color(0xFFEF4444);
  return const Color(0xFF09C15C);
}

class _ParentMessagesTab extends StatelessWidget {
  const _ParentMessagesTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) {
      return const _PlaceholderTab(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Messages',
        message: 'Connecte-toi pour accéder à la messagerie.',
      );
    }

    return ConversationsPage(currentUser: user);
  }
}

class _ParentMenuTab extends StatelessWidget {
  final _ParentChildSummary selectedChild;
  final List<_ParentChildSummary> children;
  final ValueChanged<String> onSelectChild;

  const _ParentMenuTab({
    required this.selectedChild,
    required this.children,
    required this.onSelectChild,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final firebaseService = FirebaseService();
    final userName = auth.user?.fullName ?? 'Parent';
    final email =
        auth.user?.email ?? (FirebaseAuth.instance.currentUser?.email ?? '');
    final selectedChildName = selectedChild.displayName;
    final selectedClasse = selectedChild.classe.isNotEmpty
        ? selectedChild.classe
        : 'Classe -';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 330,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2FBF71), Color(0xFF09C15C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -70,
                          top: 90,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -80,
                          top: -40,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Profil Parent',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _buildProfilePicker(
                                context,
                                auth: auth,
                                firebaseService: firebaseService,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                userName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.family_restroom_outlined,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedChildName,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            label: 'ENFANTS',
                            value: '${children.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniCard(
                            label: 'CLASSE',
                            value: selectedClasse,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _MiniCard(label: 'SUIVI', value: 'ACTIF'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations personnelles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                    child: Column(
                      children: [
                        _ProfileInfoItem(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: email.isNotEmpty ? email : '-',
                          color: const Color(0xFF4285F4),
                        ),
                        _buildDivider(),
                        _ProfileInfoItem(
                          icon: Icons.family_restroom_outlined,
                          label: 'Enfant suivi',
                          value: selectedChildName,
                          color: const Color(0xFF09C15C),
                        ),
                        _buildDivider(),
                        _ProfileInfoItem(
                          icon: Icons.school_outlined,
                          label: 'Classe',
                          value: selectedClasse,
                          color: const Color(0xFFFF6B35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enfant sélectionné',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _ChildDropdown(
                    value: selectedChild.id,
                    children: children,
                    onChanged: (id) {
                      if (id == null) return;
                      onSelectChild(id);
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
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
                    child: Column(
                      children: [
                        _buildMenuOption(
                          context,
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          color: const Color(0xFF09C15C),
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuOption(
                          context,
                          icon: Icons.dark_mode_outlined,
                          label: 'Mode sombre',
                          color: const Color(0xFFFF9800),
                          onTap: () {
                            context.read<ThemeController>().toggleDarkMode();
                          },
                        ),
                        _buildDivider(),
                        _buildMenuOption(
                          context,
                          icon: Icons.help_outline,
                          label: 'Aide & Support',
                          color: const Color(0xFF2196F3),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.read<AuthController>().logout(),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Déconnexion',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200]);
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicker(
    BuildContext context, {
    required AuthController auth,
    required FirebaseService firebaseService,
  }) {
    final user = auth.user;

    return Column(
      children: [
        UserProfileImagePicker(
          initialPhotoDataUrl: user?.photoPath,
          size: 104,
          onImagePicked: (dataUrl) async {
            if (user == null) return;
            try {
              await firebaseService.updateUserProfilePhoto(user.id, dataUrl);
              final updatedUser = user.copyWith(photoPath: dataUrl);
              auth.setUser(updatedUser);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo de profil mise à jour'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la mise à jour: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: Colors.grey[500]),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildDropdown extends StatelessWidget {
  final String value;
  final List<_ParentChildSummary> children;
  final ValueChanged<String?> onChanged;

  const _ChildDropdown({
    required this.value,
    required this.children,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: children
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.displayName, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ParentChildSummary {
  final String id;
  final String displayName;
  final String classe;

  const _ParentChildSummary({
    required this.id,
    required this.displayName,
    required this.classe,
  });

  factory _ParentChildSummary.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final displayName = (data['displayName'] as String?)?.trim();
    final name = (data['name'] as String?)?.trim();
    final prenom = (data['prenom'] as String?)?.trim();
    final nom = (data['nom'] as String?)?.trim();
    final computed = [
      prenom,
      nom,
    ].where((p) => (p ?? '').trim().isNotEmpty).join(' ').trim();

    return _ParentChildSummary(
      id: doc.id,
      displayName: (displayName?.isNotEmpty ?? false)
          ? displayName!
          : (name?.isNotEmpty ?? false)
          ? name!
          : computed.isNotEmpty
          ? computed
          : doc.id,
      classe: (data['classe'] ?? data['class'])?.toString().trim() ?? '',
    );
  }
}
