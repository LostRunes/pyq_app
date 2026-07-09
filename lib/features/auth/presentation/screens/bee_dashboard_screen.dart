import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:focus_fox/core/providers/user_profile_provider.dart';
import 'package:focus_fox/core/providers/bee_provider.dart';
import 'package:focus_fox/features/auth/presentation/widgets/bee_leaderboard_sheet.dart'; // import beeLeaderboardProvider

class BeeDashboardScreen extends ConsumerStatefulWidget {
  const BeeDashboardScreen({super.key});

  @override
  ConsumerState<BeeDashboardScreen> createState() => _BeeDashboardScreenState();
}

class _BeeDashboardScreenState extends ConsumerState<BeeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showConfetti = true;
  int? _globalRank;
  bool _isLoadingRank = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fetchGlobalRank();

    // Hide confetti after 2 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  Future<void> _fetchGlobalRank() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _globalRank = null;
          _isLoadingRank = false;
        });
      }
      return;
    }

    try {
      final killsResponse = await Supabase.instance.client
          .from('user_bee_kills')
          .select('kills')
          .eq('user_id', user.id)
          .maybeSingle();

      final kills = killsResponse?['kills'] as int? ?? 0;

      final response = await Supabase.instance.client
          .from('user_bee_kills')
          .select('user_id')
          .gt('kills', kills);

      final count = (response as List).length;

      if (mounted) {
        setState(() {
          _globalRank = count + 1;
          _isLoadingRank = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching global rank: $e');
      if (mounted) {
        setState(() {
          _globalRank = null;
          _isLoadingRank = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getRankTitle(int kills) {
    if (kills == 0) return 'Bee Chaser (Novice)';
    if (kills <= 10) return 'Hive Scout';
    if (kills <= 30) return 'Swarm Sentinel';
    if (kills <= 100) return 'Wasp Gladiator';
    return 'Supreme Hive Overlord 👑';
  }

  Color _getRankColor(int kills) {
    if (kills == 0) return Colors.grey;
    if (kills <= 10) return const Color(0xFF4BC0C0);
    if (kills <= 30) return const Color(0xFF36A2EB);
    if (kills <= 100) return const Color(0xFFFF9F40);
    return const Color(0xFFFFD700);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaderboardAsync = ref.watch(beeLeaderboardProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    // User profile and bee taps
    final userProfileAsync = ref.watch(userProfileProvider);
    final totalKills = ref.watch(beeTapCountProvider);
    final beeEnabled = ref.watch(beeEnabledProvider);

    // Color definitions based on design guidelines
    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF15112E), Color(0xFF0F0B26)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFFAF4EA), Color(0xFFFFFDF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final cardBgColor = isDark
        ? const Color(0xFF1E163B).withOpacity(0.85)
        : Colors.white;

    final borderColor = isDark
        ? const Color(0xFF4A3A75).withOpacity(0.5)
        : const Color(0xFFFFE0D6);

    final titleColor = isDark ? Colors.white : const Color(0xFF3D2F27);
    final textColor = isDark ? Colors.white70 : const Color(0xFF7A6456);

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF3D2F27),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bee Dashboard',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),
                        const Spacer(),
                        Text('🐝', style: GoogleFonts.outfit(fontSize: 26)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFFFF9F0A),
                      onRefresh: () async {
                        ref.invalidate(beeLeaderboardProvider);
                        ref.invalidate(userProfileProvider);
                        await _fetchGlobalRank();
                      },
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        children: [
                          // 1. STATS OVERVIEW CARD
                          userProfileAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF9F0A),
                              ),
                            ),
                            error: (err, stack) => const SizedBox.shrink(),
                            data: (profile) {
                              final displayName =
                                  profile?['display_name']?.toString() ??
                                  profile?['username']?.toString() ??
                                  'Fox Explorer';
                              final username =
                                  profile?['username']?.toString() ??
                                  'anonymous';
                              final avatarUrl =
                                  profile?['avatar_url']?.toString() ??
                                  'assets/images/pikachu.png';

                              final ImageProvider imageProvider =
                                  avatarUrl.startsWith('http')
                                  ? NetworkImage(avatarUrl)
                                  : AssetImage(avatarUrl) as ImageProvider;

                              return Container(
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black38
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Glow animated circular avatar
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(
                                                          0xFFFF9F0A,
                                                        ).withOpacity(
                                                          0.2 +
                                                              0.3 *
                                                                  _pulseController
                                                                      .value,
                                                        ),
                                                    blurRadius:
                                                        8 +
                                                        8 *
                                                            _pulseController
                                                                .value,
                                                    spreadRadius:
                                                        1 +
                                                        2 *
                                                            _pulseController
                                                                .value,
                                                  ),
                                                ],
                                              ),
                                              child: child,
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFFF9F0A),
                                                width: 2.0,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 28,
                                              backgroundImage: imageProvider,
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        // User Names & Rank Title
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: titleColor,
                                                ),
                                              ),
                                              Text(
                                                '@$username',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getRankColor(
                                                    totalKills,
                                                  ).withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _getRankColor(
                                                      totalKills,
                                                    ).withOpacity(0.4),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  _getRankTitle(totalKills),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getRankColor(
                                                      totalKills,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 18, thickness: 1.2),
                                    // Bee Statistics Details
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatMetric(
                                          '$totalKills',
                                          'Bees Exterminated',
                                          '🐝',
                                          isDark,
                                        ),
                                        _buildStatMetric(
                                          _isLoadingRank
                                              ? '...'
                                              : _globalRank != null
                                              ? '#$_globalRank'
                                              : 'Unranked',
                                          'Global Rank',
                                          '🏆',
                                          isDark,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Interactive Quest Toggle
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF281E48)
                                            : const Color(0xFFFFF2EC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF3B2D68)
                                              : const Color(0xFFFFE0D6),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Active Quest 🐝',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: titleColor,
                                                  ),
                                                ),
                                                Text(
                                                  beeEnabled
                                                      ? 'Bees are currently buzzing around!'
                                                      : 'Bee swarm is hidden.',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    color: beeEnabled
                                                        ? const Color(
                                                            0xFFFF9F0A,
                                                          )
                                                        : textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Transform.scale(
                                            scale: 0.85,
                                            child: Switch(
                                              value: beeEnabled,
                                              activeColor: const Color(
                                                0xFFFF9F0A,
                                              ),
                                              activeTrackColor: const Color(
                                                0xFFFF9F0A,
                                              ).withOpacity(0.3),
                                              onChanged: (val) {
                                                ref
                                                    .read(
                                                      beeEnabledProvider
                                                          .notifier,
                                                    )
                                                    .toggle();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          // 2. LEADERBOARD HEADER
                          Row(
                            children: [
                              Text(
                                'Global Leaderboard',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '🏆',
                                style: GoogleFonts.outfit(fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 3. LEADERBOARD LIST
                          leaderboardAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF9F0A),
                                ),
                              ),
                            ),
                            error: (err, stack) => Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                ),
                                child: Text(
                                  'Failed to load leaderboard.',
                                  style: GoogleFonts.outfit(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                            data: (entries) {
                              if (entries.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40.0,
                                    ),
                                    child: Text(
                                      'No records yet. Taps bees to join!',
                                      style: GoogleFonts.outfit(
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: entries.asMap().entries.map((item) {
                                  final index = item.key;
                                  final entry = item.value;
                                  final kills = entry['kills'] as int;
                                  final userId = entry['user_id'] as String;
                                  final isMe =
                                      currentUser != null &&
                                      userId == currentUser.id;

                                  final profile =
                                      entry['user_profiles']
                                          as Map<String, dynamic>?;
                                  final displayName =
                                      profile?['display_name']?.toString() ??
                                      profile?['username']?.toString() ??
                                      'Exterminator';
                                  final username =
                                      profile?['username']?.toString() ??
                                      'anonymous';
                                  final avatarUrl =
                                      profile?['avatar_url']?.toString() ??
                                      'assets/images/pikachu.png';

                                  final rank = index + 1;

                                  // UI highlight for current user
                                  final itemBg = isMe
                                      ? (isDark
                                            ? const Color(0xFF2C2258)
                                            : const Color(0xFFFFEFEB))
                                      : cardBgColor;

                                  final itemBorder = isMe
                                      ? Border.all(
                                          color: const Color(0xFFFF9F0A),
                                          width: 1.5,
                                        )
                                      : Border.all(
                                          color: borderColor,
                                          width: 1.0,
                                        );

                                  final ImageProvider imageProvider =
                                      avatarUrl.startsWith('http')
                                      ? NetworkImage(avatarUrl)
                                      : AssetImage(avatarUrl) as ImageProvider;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: itemBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: itemBorder,
                                      boxShadow: isMe
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFF9F0A,
                                                ).withOpacity(0.15),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                      leading: SizedBox(
                                        width: 80,
                                        child: Row(
                                          children: [
                                            _buildRankBadge(rank, isDark),
                                            const SizedBox(width: 12),
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isMe
                                                      ? const Color(0xFFFF9F0A)
                                                      : Colors.transparent,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundImage: imageProvider,
                                                backgroundColor:
                                                    Colors.transparent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontWeight: isMe
                                                  ? FontWeight.w900
                                                  : FontWeight.bold,
                                              color: isMe
                                                  ? (isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF5A2900,
                                                          ))
                                                  : (isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF3D2F27,
                                                          )),
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '@$username',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: isMe
                                                  ? const Color(0xFFFF9F0A)
                                                  : textColor,
                                              fontWeight: isMe
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF281E48)
                                              : const Color(0xFFFFF2EC),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF3B2D68)
                                                : const Color(0xFFFFE0D6),
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
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: Lottie.asset(
                    'json/Confeti.json',
                    fit: BoxFit.cover,
                    repeat: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetric(
    String value,
    String label,
    String icon,
    bool isDark,
  ) {
    final titleColor = isDark ? Colors.white : const Color(0xFF3D2F27);
    final textColor = isDark ? Colors.white60 : const Color(0xFF7A6456);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: GoogleFonts.outfit(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF9F0A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
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
