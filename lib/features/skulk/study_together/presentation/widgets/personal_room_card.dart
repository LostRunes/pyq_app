import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/study_room.dart';
import '../providers/study_together_providers.dart';

class PersonalRoomCard extends ConsumerWidget {
  final StudyRoom room;

  const PersonalRoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate activity
    final now = DateTime.now();
    final diff = now.difference(room.lastMessageAt);
    String activityText;
    Color indicatorColor;

    if (diff.inMinutes < 15) {
      activityText = 'active now';
      indicatorColor = Colors.greenAccent;
    } else if (diff.inHours < 1) {
      activityText = 'active recently';
      indicatorColor = Colors.orangeAccent;
    } else {
      activityText = 'quiet';
      indicatorColor = Colors.grey[500]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1428) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F2654) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/study-together/chat',
              arguments: room,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E203F)
                        : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    room.isVoiceEnabled
                        ? Icons.volume_up_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFFC084FC) : const Color(0xFF6B21A8),
                  ),
                ),
                const SizedBox(width: 12),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF3C2E4C)
                                  : const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              room.subjectId ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Activity & voice indicator
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activityText,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (room.isVoiceEnabled && room.participantCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.headset_mic_rounded,
                              size: 10,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room.participantCount} active',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 3-Dots actions menu
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                  onPressed: () => _showActionsMenu(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionsMenu(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final isCreator = room.createdBy != null && room.createdBy == user?.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                room.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Room Code: ${room.subjectId}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.blue),
                title: Text('Copy Room Code', style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: room.subjectId ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room code copied to clipboard!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.green),
                title: Text('Share Invitation', style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    'Join my study room "${room.name}" on Focus Fox! Use 6-character room code to join: ${room.subjectId}',
                  );
                },
              ),
              const Divider(),
              if (isCreator)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: Text('Delete Room', style: GoogleFonts.outfit(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, ref);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.exit_to_app_rounded, color: Colors.orange),
                  title: Text('Leave Room', style: GoogleFonts.outfit(color: Colors.orange)),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref
                        .read(joinedRoomIdsProvider.notifier)
                        .removeRoom(room.id);
                    ref.invalidate(studyRoomsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Left room: ${room.name}')),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Room?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to permanently delete "${room.name}"? This action cannot be undone and all chat history will be lost.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref
                      .read(roomOperationsProvider)
                      .deleteRoom(room.id);
                  await ref
                      .read(joinedRoomIdsProvider.notifier)
                      .removeRoom(room.id);
                  ref.invalidate(studyRoomsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Room "${room.name}" deleted.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting room: $e')),
                    );
                  }
                }
              },
              child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
