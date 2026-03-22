import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

enum _NotifFilter { all, unread }

class _NotificationsPageState extends State<NotificationsPage> {
  _NotifFilter _filter = _NotifFilter.all;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: uid == null
          ? const _CenteredMessage(
              icon: Icons.lock_outline,
              title: 'Connexion requise',
              message: 'Connecte-toi pour voir tes notifications.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
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

                final notifs = snapshot.data!.docs
                    .map(_AppNotification.fromDoc)
                    .toList(growable: false);

                final unreadCount =
                    notifs.where((n) => !n.isRead).length;

                final filtered = switch (_filter) {
                  _NotifFilter.all => notifs,
                  _NotifFilter.unread =>
                    notifs.where((n) => !n.isRead).toList(growable: false),
                };

                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _SegmentButton(
                            label: 'Toutes',
                            selected: _filter == _NotifFilter.all,
                            onTap: () => setState(() => _filter = _NotifFilter.all),
                          ),
                          const SizedBox(width: 10),
                          _SegmentButton(
                            label: 'Non lues',
                            selected: _filter == _NotifFilter.unread,
                            badge: unreadCount,
                            onTap: () =>
                                setState(() => _filter = _NotifFilter.unread),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: unreadCount == 0
                                ? null
                                : () => _markAllRead(uid, notifs),
                            child: const Text(
                              'Tout lire',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const _CenteredMessage(
                              icon: Icons.notifications_none,
                              title: 'Aucune notification',
                              message: 'Rien à afficher pour le moment.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final n = filtered[index];
                                return _NotificationCard(
                                  notification: n,
                                  onTap: () => _markRead(n),
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

  Future<void> _markRead(_AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .update({'read': true, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (_) {
      // Ignore: UI is best-effort
    }
  }

  Future<void> _markAllRead(String uid, List<_AppNotification> notifs) async {
    final unread = notifs.where((n) => !n.isRead).toList(growable: false);
    if (unread.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in unread) {
        final ref =
            FirebaseFirestore.instance.collection('notifications').doc(n.id);
        batch.update(ref, {'read': true, 'updatedAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    } catch (_) {
      // Ignore: UI is best-effort
    }
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF2563EB) : const Color(0xFFF1F3F5);
    final fg = selected ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.25) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _NotificationVisual.fromType(notification.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : const Color(0xFF93C5FD),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: visual.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(visual.icon, color: visual.fg, size: 22),
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
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDateTime(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    const months = [
      '',
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];

    final dd = date.day;
    final mm = months[date.month];
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd $mm, $hh:$min';
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color bg;
  final Color fg;

  const _NotificationVisual({
    required this.icon,
    required this.bg,
    required this.fg,
  });

  factory _NotificationVisual.fromType(String type) {
    switch (type) {
      case 'note':
        return const _NotificationVisual(
          icon: Icons.school_outlined,
          bg: Color(0xFFE8F0FE),
          fg: Color(0xFF2563EB),
        );
      case 'homework':
        return const _NotificationVisual(
          icon: Icons.menu_book_outlined,
          bg: Color(0xFFE9F7EE),
          fg: Color(0xFF22C55E),
        );
      case 'message':
        return const _NotificationVisual(
          icon: Icons.chat_bubble_outline,
          bg: Color(0xFFF4ECFF),
          fg: Color(0xFF8B5CF6),
        );
      default:
        return const _NotificationVisual(
          icon: Icons.notifications_none,
          bg: Color(0xFFF1F3F5),
          fg: Color(0xFF6B7280),
        );
    }
  }
}

class _AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  const _AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  static _AppNotification fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = (data['title'] as String?) ?? (data['titre'] as String?) ?? 'Notification';
    final body = (data['body'] as String?) ??
        (data['message'] as String?) ??
        (data['contenu'] as String?) ??
        '';
    final type = (data['type'] as String?) ?? '';

    final createdRaw = data['createdAt'] ?? data['date'] ?? data['timestamp'];
    final createdAt = createdRaw is Timestamp
        ? createdRaw.toDate()
        : (createdRaw is DateTime ? createdRaw : DateTime.now());

    final readRaw = data['read'] ?? data['isRead'] ?? data['lu'];
    final isRead = readRaw == true;

    return _AppNotification(
      id: doc.id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: isRead,
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
