import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/study_room.dart';
import '../../data/models/room_message.dart';
import '../providers/study_together_providers.dart';

class StudyRoomChatScreen extends ConsumerStatefulWidget {
  final StudyRoom room;

  const StudyRoomChatScreen({
    super.key,
    required this.room,
  });

  @override
  ConsumerState<StudyRoomChatScreen> createState() => _StudyRoomChatScreenState();
}

class _StudyRoomChatScreenState extends ConsumerState<StudyRoomChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // If user scrolled near the top of the reversed list (older messages), load more
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(roomChatProvider(widget.room.id).notifier).loadMore();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message too long (max 2000 characters).')),
      );
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(roomChatProvider(widget.room.id).notifier).sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = ref.watch(roomChatProvider(widget.room.id));
    final presenceCount = ref.watch(roomPresenceProvider(widget.room.id));
    final chatNotifier = ref.read(roomChatProvider(widget.room.id).notifier);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Row(
          children: [
            Text(widget.room.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$presenceCount online',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
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
      body: SafeArea(
        child: Column(
          children: [
            // Message List
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.room.icon,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet.',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start the late-night academic chaos ☕',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      reverse: true,
                      itemCount: messages.length + (chatNotifier.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        final message = messages[index];
                        return _MessageTile(message: message, isDark: isDark);
                      },
                    ),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282828) : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.outfit(fontSize: 14),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type academic thoughts...',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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
}

class _MessageTile extends StatelessWidget {
  final RoomMessage message;
  final bool isDark;

  const _MessageTile({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTimestamp(message.createdAt);
    final initial = (message.senderDisplayName ?? message.senderUsername ?? '?')
        .substring(0, 1)
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? const Color(0xFF383838) : const Color(0xFFE2E6EA),
            backgroundImage: message.senderAvatarUrl != null
                ? NetworkImage(message.senderAvatarUrl!)
                : null,
            child: message.senderAvatarUrl == null
                ? Text(
                    initial,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      message.senderDisplayName ?? 'User',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '@${message.senderUsername ?? "anonymous"}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message.message,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF2C2C2C),
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

  String _formatTimestamp(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour == 0 ? 12 : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final amPm = localDt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}
