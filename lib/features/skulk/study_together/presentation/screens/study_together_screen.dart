import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/study_together_providers.dart';
import '../../data/models/study_room.dart';

class StudyTogetherScreen extends ConsumerWidget {
  const StudyTogetherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomsAsync = ref.watch(studyRoomsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        title: Text(
          'Study Together 🎓',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Failed to load study spaces.',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(studyRoomsProvider),
                child: Text('Retry', style: GoogleFonts.outfit()),
              ),
            ],
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                'No study rooms found ☕',
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Separate general/community and subject rooms if any
          final generalRooms = rooms.where((r) => r.type != 'subject').toList();
          final subjectRooms = rooms.where((r) => r.type == 'subject').toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(studyRoomsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                if (generalRooms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      '🔥 Active Rooms',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                  ...generalRooms.map((room) => _buildRoomCard(context, room, isDark)),
                  const SizedBox(height: 24),
                ],
                if (subjectRooms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      '📘 Subject Discussion Rooms',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                  ...subjectRooms.map((room) => _buildRoomCard(context, room, isDark)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, StudyRoom room, bool isDark) {
    // Generate activity text based on last_message_at
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
      activityText = 'quiet right now';
      indicatorColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon wrapper
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF0F4FA),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    room.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                // Room info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (room.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          room.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Ambient activity indicator
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activityText,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
