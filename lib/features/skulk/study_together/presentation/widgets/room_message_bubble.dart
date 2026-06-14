import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../../data/models/room_message.dart';

class RoomMessageBubble extends StatefulWidget {
  final RoomMessage message;
  final double dragOffset;
  final VoidCallback onReply;

  const RoomMessageBubble({
    super.key,
    required this.message,
    required this.dragOffset,
    required this.onReply,
  });

  @override
  State<RoomMessageBubble> createState() => _RoomMessageBubbleState();
}

class _RoomMessageBubbleState extends State<RoomMessageBubble> with SingleTickerProviderStateMixin {
  double _replyDragOffset = 0.0;
  late final AnimationController _replyAnimController;

  @override
  void initState() {
    super.initState();
    _replyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _replyAnimController.dispose();
    super.dispose();
  }

  ImageProvider _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/images/pikachu.png');
    }
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return NetworkImage(avatarUrl);
    }
    return AssetImage(avatarUrl);
  }

  String _formatTimestamp(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour == 0
        ? 12
        : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final amPm = localDt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = widget.message.userId == currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe
        ? Theme.of(context).colorScheme.primary
        : (isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF));

    final textColor = isMe
        ? Colors.white
        : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF0F1419));

    final timeStr = _formatTimestamp(widget.message.createdAt);

    // Parse Reply Prefix if present: [reply:User:Text]ActualMessage
    String displayMessage = widget.message.message;
    String? repliedToUser;
    String? repliedToText;

    final replyRegex = RegExp(r'^\[reply:([^:]*):([^\]]*)\]([\s\S]*)');
    final match = replyRegex.firstMatch(widget.message.message);
    if (match != null) {
      repliedToUser = match.group(1);
      repliedToText = match.group(2);
      displayMessage = match.group(3) ?? displayMessage;
    }

    // Parse Image prefixes: [image:URL]
    final List<String> imageUrls = [];
    final imageRegex = RegExp(r'\[image:([^\]]*)\]');
    final matches = imageRegex.allMatches(displayMessage);
    for (final m in matches) {
      final url = m.group(1);
      if (url != null) {
        imageUrls.add(url);
      }
    }
    displayMessage = displayMessage.replaceAll(imageRegex, '').trim();

    if (repliedToText != null) {
      repliedToText = repliedToText.replaceAll(imageRegex, '[Image]').trim();
      if (repliedToText.isEmpty) {
        repliedToText = '[Image]';
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDragRight = !isMe;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        // Swipe to reply logic (independent from list drag)
        if (widget.dragOffset == 0.0) {
          setState(() {
            if (isDragRight) {
              _replyDragOffset = (_replyDragOffset + details.delta.dx).clamp(0.0, 70.0);
            } else {
              _replyDragOffset = (_replyDragOffset + details.delta.dx).clamp(-70.0, 0.0);
            }
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_replyDragOffset.abs() >= 50.0) {
          widget.onReply();
        }
        _replyAnimController.forward(from: 0.0);
        final start = _replyDragOffset;
        _replyAnimController.addListener(() {
          setState(() {
            _replyDragOffset = ui.lerpDouble(start, 0.0, _replyAnimController.value)!;
          });
        });
      },
      child: Container(
        clipBehavior: Clip.none,
        child: Transform.translate(
          offset: Offset(widget.dragOffset + _replyDragOffset, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Message Bubble row (occupies full screen width)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  children: [
                    // Reply Icon behind the bubble
                    Positioned(
                      left: isDragRight ? -36.0 : null,
                      right: !isDragRight ? -36.0 : null,
                      child: Opacity(
                        opacity: (_replyDragOffset.abs() / 50.0).clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262626) : const Color(0xFFF2F2F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.reply_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    // The actual bubble row
                    Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: isDark
                                  ? const Color(0xFF383838)
                                  : const Color(0xFFE2E6EA),
                              backgroundImage: _getAvatarProvider(widget.message.senderAvatarUrl),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                                  child: Text(
                                    widget.message.senderDisplayName ?? widget.message.senderUsername ?? 'User',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 6),
                                    bottomRight: Radius.circular(isMe ? 6 : 20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Reply preview inside the bubble
                                    if (repliedToUser != null) ...[
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.white.withOpacity(0.15)
                                              : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2E2E2)),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              repliedToUser,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: isMe ? Colors.white70 : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              repliedToText ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: isMe ? Colors.white60 : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (imageUrls.isNotEmpty) ...[
                                      Container(
                                        constraints: const BoxConstraints(maxHeight: 240),
                                        margin: EdgeInsets.only(bottom: displayMessage.isNotEmpty ? 6 : 0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: imageUrls.length == 1
                                              ? GestureDetector(
                                                  onTap: () => _showFullScreenImage(context, imageUrls.first),
                                                  child: Image.network(
                                                    imageUrls.first,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        height: 150,
                                                        width: 200,
                                                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E2E2),
                                                        child: const Center(
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : GridView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    crossAxisSpacing: 4,
                                                    mainAxisSpacing: 4,
                                                  ),
                                                  itemCount: imageUrls.length,
                                                  itemBuilder: (context, idx) {
                                                    final url = imageUrls[idx];
                                                    return GestureDetector(
                                                      onTap: () => _showFullScreenImage(context, url),
                                                      child: Image.network(
                                                        url,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                    ],
                                    if (displayMessage.isNotEmpty)
                                      Text(
                                        displayMessage,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: textColor,
                                          height: 1.3,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMe) const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),

              // Off-screen slide-in timestamp (positioned exactly beyond screen edge)
              Positioned(
                right: -70,
                top: 0,
                bottom: 0,
                width: 70,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    timeStr,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
