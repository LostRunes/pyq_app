import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/core/providers/user_profile_provider.dart';

/// FutureProvider that fetches the top 50 bee killers from the database,
/// joining with user profiles to retrieve their username, display name, and avatar.
final beeLeaderboardProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('user_bee_kills')
      .select('kills, user_id, user_profiles(username, display_name, avatar_url)')
      .order('kills', ascending: false)
      .limit(50);
  
  return List<Map<String, dynamic>>.from(response);
});

class BeeLeaderboardSheet extends ConsumerWidget {
  const BeeLeaderboardSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaderboardAsync = ref.watch(beeLeaderboardProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    // Dark mode gradient: deep indigo/violet night sky
    // Light mode gradient: warm cream-orange
    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF1E163B), Color(0xFF0F0B26)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFF6F0), Color(0xFFFDECE5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final borderColor = isDark ? const Color(0xFF4A3A75) : const Color(0xFFFFDDD2);
    final titleColor = isDark ? Colors.white : const Color(0xFF5A2900);
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          left: BorderSide(color: borderColor, width: 1.5),
          right: BorderSide(color: borderColor, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🐝',
                    style: GoogleFonts.outfit(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bee Exterminators',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Who has killed the most bees?',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Leaderboard entries list
            Expanded(
              child: leaderboardAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF9F0A),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Failed to load leaderboard. Please check your connection.',
                      style: GoogleFonts.outfit(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Text(
                        'No records yet. Start tapping bees!',
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: entries.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final kills = entry['kills'] as int;
                      final userId = entry['user_id'] as String;
                      final isMe = currentUser != null && userId == currentUser.id;

                      // Extract nested profile data
                      final profile = entry['user_profiles'] as Map<String, dynamic>?;
                      final displayName = profile?['display_name']?.toString() ?? 
                          profile?['username']?.toString() ?? 'Exterminator';
                      final avatarUrl = profile?['avatar_url']?.toString() ?? 'assets/images/pikachu.png';

                      final rank = index + 1;
                      
                      // Highlight current user
                      final itemBg = isMe
                          ? (isDark ? const Color(0xFF2C2258) : const Color(0xFFFFEFEB))
                          : Colors.transparent;
                      final itemBorder = isMe
                          ? Border.all(color: const Color(0xFFFF9F0A), width: 1.5)
                          : Border.all(color: Colors.transparent);

                      // Image Provider selection
                      final ImageProvider imageProvider = avatarUrl.startsWith('http')
                          ? NetworkImage(avatarUrl)
                          : AssetImage(avatarUrl) as ImageProvider;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(16),
                          border: itemBorder,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: SizedBox(
                            width: 80,
                            child: Row(
                              children: [
                                // Rank Badge
                                _buildRankBadge(rank, isDark),
                                const SizedBox(width: 12),
                                // Avatar
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isMe ? const Color(0xFFFF9F0A) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundImage: imageProvider,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: isMe
                              ? Text(
                                  'You',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFFFF9F0A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF281E48) : const Color(0xFFFFF2EC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF3B2D68) : const Color(0xFFFFE0D6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$kills',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: const Color(0xFFFF9F0A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '🐝',
                                  style: GoogleFonts.outfit(fontSize: 12),
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
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isDark) {
    if (rank == 1) {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFFFFD700),
        child: Text('🥇', style: TextStyle(fontSize: 12)),
      );
    } else if (rank == 2) {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFFC0C0C0),
        child: Text('🥈', style: TextStyle(fontSize: 12)),
      );
    } else if (rank == 3) {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFFCD7F32),
        child: Text('🥉', style: TextStyle(fontSize: 12)),
      );
    } else {
      return CircleAvatar(
        radius: 12,
        backgroundColor: isDark ? Colors.white10 : Colors.black12,
        child: Text(
          '$rank',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }
  }
}
