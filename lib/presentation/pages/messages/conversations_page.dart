import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/conversation_model.dart';
import '../../../models/user_model.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  final User currentUser;

  const ConversationsPage({super.key, required this.currentUser});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<User?> _loadOtherUserProfile(Conversation conversation) async {
    try {
      final otherUserId = conversation.participants.firstWhere(
        (id) => id != widget.currentUser.id,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) return null;
      return await _firebaseService.getUserProfile(otherUserId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildAvatar({
    required String initials,
    String? photoPath,
    double radius = 22,
  }) {
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;

    if (hasPhoto && photoPath.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoPath),
      );
    }

    if (hasPhoto && photoPath.startsWith('data:image')) {
      try {
        final bytes = base64Decode(photoPath.split(',').last);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        // Fallback sur les initiales si data URL invalide.
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8F8EF),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF09C15C),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<List<User>> _loadAvailableRecipients() async {
    final role = widget.currentUser.role;

    if (role == UserRoles.teacher) {
      final students = await _firebaseService.getUsersByRole(UserRoles.student);
      final parents = await _firebaseService.getUsersByRole(UserRoles.parent);
      return [
        ...students,
        ...parents,
      ].where((u) => u.id != widget.currentUser.id).toList(growable: false);
    }

    if (role == UserRoles.student || role == UserRoles.parent) {
      final teachers = await _firebaseService.getUsersByRole(UserRoles.teacher);
      return teachers
          .where((u) => u.id != widget.currentUser.id)
          .toList(growable: false);
    }

    final teachers = await _firebaseService.getUsersByRole(UserRoles.teacher);
    return teachers
        .where((u) => u.id != widget.currentUser.id)
        .toList(growable: false);
  }

  String _recipientEmptyMessage() {
    final role = widget.currentUser.role;
    if (role == UserRoles.teacher) {
      return 'Aucun élève ou parent trouvé.';
    }
    return 'Aucun enseignant trouvé.';
  }

  String _recipientHelpMessage() {
    final role = widget.currentUser.role;
    if (role == UserRoles.teacher) {
      return 'Appuyez sur Nouveau pour démarrer un échange avec un élève ou un parent.';
    }
    return 'Appuyez sur Nouveau pour démarrer un échange avec un enseignant.';
  }

  Future<void> _startConversation() async {
    try {
      final recipients = await _loadAvailableRecipients();
      if (!mounted) return;

      if (recipients.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_recipientEmptyMessage())));
        return;
      }

      final selected = await showModalBottomSheet<User>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: ListView.separated(
              itemCount: recipients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final recipient = recipients[index];
                return ListTile(
                  leading: _buildAvatar(
                    initials: _initials(recipient.fullName),
                    photoPath: recipient.photoPath,
                  ),
                  title: Text(recipient.fullName),
                  subtitle: Text(
                    '${UserRoles.getLabel(recipient.role)} • ${recipient.email}',
                  ),
                  onTap: () => Navigator.of(context).pop(recipient),
                );
              },
            ),
          );
        },
      );

      if (selected == null || !mounted) return;

      final conversationId = await _firebaseService.getOrCreateConversation(
        currentUser: widget.currentUser,
        otherUser: selected,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            currentUser: widget.currentUser,
            conversationId: conversationId,
            title: selected.fullName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Messagerie',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _startConversation,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Nouveau'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09C15C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: _firebaseService.streamConversations(
                widget.currentUser.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final conversations = snapshot.data!;
                if (conversations.isEmpty) {
                  return _EmptyMessagesState(
                    helpMessage: _recipientHelpMessage(),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final title = conversation.titleFor(widget.currentUser.id);
                    final unread = conversation.unreadFor(
                      widget.currentUser.id,
                    );
                    final subtitle = conversation.lastMessage.isNotEmpty
                        ? conversation.lastMessage
                        : 'Aucun message pour le moment';

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await _firebaseService.markConversationAsRead(
                            conversationId: conversation.id,
                            userId: widget.currentUser.id,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                currentUser: widget.currentUser,
                                conversationId: conversation.id,
                                title: title,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE9EDF3)),
                          ),
                          child: Row(
                            children: [
                              FutureBuilder<User?>(
                                future: _loadOtherUserProfile(conversation),
                                builder: (context, snapshot) {
                                  return _buildAvatar(
                                    radius: 22,
                                    initials: _initials(title),
                                    photoPath: snapshot.data?.photoPath,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF09C15C),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  final String helpMessage;

  const _EmptyMessagesState({required this.helpMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 10),
            const Text(
              'Aucune conversation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              helpMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
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
