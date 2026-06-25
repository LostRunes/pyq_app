import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../study_together/data/models/study_room.dart';
import '../providers/skulk_providers.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(skulkRepositoryProvider);
      return repo.getNotifications();
    });

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141414)
          : const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final repo = ref.read(skulkRepositoryProvider);
              await repo.markAllNotificationsRead();
              ref.invalidate(notificationsProvider);
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load: $e', style: GoogleFonts.outfit()),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 60,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet 🔔',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You'll be notified when someone answers your doubts.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group into Today vs Earlier
          final now = DateTime.now();
          final today = <Map<String, dynamic>>[];
          final earlier = <Map<String, dynamic>>[];

          for (final n in notifications) {
            final dt =
                DateTime.tryParse(n['created_at']?.toString() ?? '') ?? now;
            if (now.difference(dt).inHours < 24) {
              today.add(n);
            } else {
              earlier.add(n);
            }
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (today.isNotEmpty) ...[
                  _sectionHeader('Today', isDark),
                  ...today.map(
                    (n) => _NotificationTile(
                      n: n,
                      isDark: isDark,
                      onTap: () {
                        _handleNotificationTap(context, n);
                      },
                    ),
                  ),
                ],
                if (earlier.isNotEmpty) ...[
                  _sectionHeader('Earlier', isDark),
                  ...earlier.map(
                    (n) => _NotificationTile(
                      n: n,
                      isDark: isDark,
                      onTap: () {
                        _handleNotificationTap(context, n);
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> n) async {
    final type = n['type']?.toString();
    final postId = n['post_id']?.toString();
    if (postId == null || postId.isEmpty) return;

    if (type == 'mention' || type == 'tag') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('study_rooms')
            .select()
            .eq('id', postId)
            .maybeSingle();
        
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading spinner
          if (res != null) {
            final room = StudyRoom.fromJson(res);
            Navigator.pushNamed(context, '/study-together/chat', arguments: room);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Study room not found or deleted.')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading spinner
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error joining room: $e')),
          );
        }
      }
    } else {
      Navigator.pushNamed(context, '/skulk_detail', arguments: postId);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> n;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.n,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = n['read'] as bool? ?? true;
    final type = n['type']?.toString() ?? '';
    final message = n['message']?.toString() ?? '';
    final dt =
        DateTime.tryParse(n['created_at']?.toString() ?? '') ?? DateTime.now();

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'answer':
        icon = Icons.check_circle_outline_rounded;
        iconColor = Colors.green;
        break;
      case 'comment':
        icon = Icons.chat_bubble_outline_rounded;
        iconColor = Colors.blue;
        break;
      case 'accepted':
        icon = Icons.emoji_events_rounded;
        iconColor = Colors.amber;
        break;
      case 'mention':
      case 'tag':
        icon = Icons.alternate_email_rounded;
        iconColor = Colors.orange;
        break;
      case 'upvote':
        icon = Icons.thumb_up_alt_outlined;
        iconColor = Colors.pink;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = Colors.purple;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? const Color(0xFF1C1C1C) : Colors.white)
              : (isDark
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? (isDark ? Colors.grey[850]! : Colors.grey[200]!)
                : Theme.of(context).colorScheme.primary.withOpacity(0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatRelativeTime(dt),
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
