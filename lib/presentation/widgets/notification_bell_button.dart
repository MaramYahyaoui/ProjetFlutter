import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/notifications/notifications_page.dart';

class NotificationBellButton extends StatelessWidget {
  final Color iconColor;
  final double iconSize;
  final bool dense;

  const NotificationBellButton({
    super.key,
    this.iconColor = Colors.black87,
    this.iconSize = 24,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _buildBell(context, unreadCount: 0);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final unreadCount = docs.where((doc) {
          final data = doc.data();
          final readRaw = data['read'] ?? data['isRead'] ?? data['lu'];
          return readRaw != true;
        }).length;

        return _buildBell(context, unreadCount: unreadCount);
      },
    );
  }

  Widget _buildBell(BuildContext context, {required int unreadCount}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          padding: dense ? EdgeInsets.zero : null,
          constraints: dense
              ? const BoxConstraints.tightFor(width: 32, height: 32)
              : null,
          icon: Icon(
            Icons.notifications_outlined,
            color: iconColor,
            size: iconSize,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: dense ? -2 : 6,
            top: dense ? -3 : 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
