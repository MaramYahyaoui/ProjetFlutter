import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';
import '../pages/messages/chat_page.dart';
import '../../models/conversation_model.dart';

class RecentMessagesPreview extends StatelessWidget {
  final User currentUser;
  final VoidCallback onOpenAll;
  final Color accentColor;

  const RecentMessagesPreview({
    super.key,
    required this.currentUser,
    required this.onOpenAll,
    this.accentColor = const Color(0xFF2F6DF6),
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<List<Conversation>>(
      stream: firebaseService.streamConversations(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final conversations = snapshot.data!;
        final previewConversations = conversations
            .take(2)
            .toList(growable: false);
        final unreadTotal = conversations.fold<int>(
          0,
          (sum, c) => sum + c.unreadFor(currentUser.id),
        );

        if (conversations.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Aucune conversation pour le moment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onOpenAll,
                  child: const Text('Voir tous les messages'),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Messages récents',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Text(
                      unreadTotal > 0
                          ? '$unreadTotal nouveaux'
                          : '${conversations.length} conversations',
                      style: const TextStyle(
                        color: Color(0xFF8A94A6),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...previewConversations.asMap().entries.map((entry) {
                final index = entry.key;
                final conversation = entry.value;
                final title = conversation.titleFor(currentUser.id);
                final unread = conversation.unreadFor(currentUser.id);
                final subtitle = conversation.lastMessage.isEmpty
                    ? 'Aucun message pour le moment'
                    : conversation.lastMessage;
                final initials = _initials(title);
                final hasTime = conversation.lastMessageAt != null;

                return Container(
                  margin: EdgeInsets.fromLTRB(
                    10,
                    index == 0 ? 0 : 6,
                    10,
                    index == previewConversations.length - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: unread > 0
                        ? const Color(0xFFF3F6FB)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    onTap: () async {
                      await firebaseService.markConversationAsRead(
                        conversationId: conversation.id,
                        userId: currentUser.id,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            currentUser: currentUser,
                            conversationId: conversation.id,
                            title: title,
                          ),
                        ),
                      );
                    },
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FutureBuilder<User?>(
                          future: _loadOtherUserProfile(
                            firebaseService,
                            conversation,
                            currentUser.id,
                          ),
                          builder: (context, snapshot) {
                            final otherUser = snapshot.data;
                            final photoUrl = otherUser?.photoPath;
                            final hasPhoto =
                                photoUrl != null && photoUrl.isNotEmpty;

                            if (hasPhoto && photoUrl.startsWith('http')) {
                              return CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(photoUrl),
                              );
                            }

                            if (hasPhoto && photoUrl.startsWith('data:image')) {
                              try {
                                final bytes = base64Decode(
                                  photoUrl.split(',').last,
                                );
                                return CircleAvatar(
                                  radius: 28,
                                  backgroundImage: MemoryImage(bytes),
                                );
                              } catch (_) {
                                // On garde le fallback sur les initiales si la data URL est invalide.
                              }
                            }

                            return CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFEAF2FF),
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: SizedBox(
                      width: 72,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (hasTime)
                            Text(
                              _formatMessageTime(conversation.lastMessageAt!),
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFC4CAD4),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Divider(height: 1),
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                onTap: onOpenAll,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Voir tous les messages',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF67758E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatMessageTime(DateTime date) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfMessageDay = DateTime(date.year, date.month, date.day);

  if (startOfMessageDay == startOfToday) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  if (startOfMessageDay == startOfToday.subtract(const Duration(days: 1))) {
    return 'Hier';
  }

  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd/$mm';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) return '--';
  if (parts.length == 1) {
    final value = parts.first;
    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Future<User?> _loadOtherUserProfile(
  FirebaseService firebaseService,
  Conversation conversation,
  String currentUserId,
) async {
  try {
    final otherUserId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return null;
    return await firebaseService.getUserProfile(otherUserId);
  } catch (_) {
    return null;
  }
}
