import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Student Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                ),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF7ED),
                    const Color(0xFFFFF1F2).withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // Hero Avatar Card
                _buildHeroCard(context, isDark),
                const SizedBox(height: 24),
                // Quick Statistics Grid
                _buildStatsGrid(context, isDark),
                const SizedBox(height: 24),
                // Preparation Progress Card
                _buildProgressCard(context, isDark),
                const SizedBox(height: 24),
                // Achievements / Badges Section
                _buildBadgesSection(context, isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cardColor = isDark ? const Color(0xFF251E4E).withOpacity(0.85) : Colors.white;
    final accentColor = isDark ? const Color(0xFFC0A6FF) : const Color(0xFF7D4B26);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tappable Avatar with glow
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pikachu says: Study hard and you will unleash your maximum power! ⚡',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFFC0A6FF), const Color(0xFF7A58D3)]
                          : [const Color(0xFFFDBA74), const Color(0xFFF97316)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? const Color(0xFF15112E) : const Color(0xFFFFF7ED),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      'assets/images/pikachu.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // User Details
          Text(
            'Alex Mercer',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF3D2F27),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'alex.mercer@reva.edu.in',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
          const SizedBox(height: 16),
          // Roll No / Branch / Sem details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(
                context,
                isDark,
                icon: Icons.badge_outlined,
                label: 'Roll No',
                val: '22CS30024',
              ),
              _buildDetailItem(
                context,
                isDark,
                icon: Icons.school_outlined,
                label: 'Branch',
                val: 'CSE',
              ),
              _buildDetailItem(
                context,
                isDark,
                icon: Icons.calendar_today_outlined,
                label: 'Semester',
                val: 'S4',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String val,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isDark) {
    final stats = [
      {'icon': '🔥', 'title': 'Study Streak', 'value': '7 Days'},
      {'icon': '🏆', 'title': 'Contrib. Pts', 'value': '1,450'},
      {'icon': '📚', 'title': 'Notes Shared', 'value': '3 Docs'},
      {'icon': '⚡', 'title': 'AI Solved', 'value': '14 PYQs'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final item = stats[index];
        final cardColor = isDark ? const Color(0xFF251E4E).withOpacity(0.85) : Colors.white;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7).withOpacity(0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    item['icon']!,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['title']!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              Text(
                item['value']!,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cardColor = isDark ? const Color(0xFF251E4E).withOpacity(0.85) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Syllabus Coverage 📈',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Completion',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Text(
                '68%',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF15112E) : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prep Status',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    Text(
                      'Excellent Progress 🚀',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target GPA',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    Text(
                      '9.2 / 10.0 🎯',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cardColor = isDark ? const Color(0xFF251E4E).withOpacity(0.85) : Colors.white;

    final badges = [
      {'icon': '🌅', 'title': 'Early Bird', 'unlocked': true, 'subtitle': 'Study before 6 AM'},
      {'icon': '🥷', 'title': 'Note Ninja', 'unlocked': true, 'subtitle': 'Shared 3+ notes'},
      {'icon': '🧠', 'title': 'AI Solver', 'unlocked': true, 'subtitle': 'Solved 10+ with AI'},
      {'icon': '⭐️', 'title': 'Streak Star', 'unlocked': false, 'subtitle': 'Reach a 10D streak'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Earned Badges & Medals 🏅',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final badge = badges[i];
              final unlocked = badge['unlocked'] as bool;

              return Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? (isDark ? const Color(0x33C0A6FF) : const Color(0xFFFFF7ED))
                          : (isDark ? const Color(0x11FFFFFF) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: unlocked
                            ? (isDark ? const Color(0xFFC0A6FF).withOpacity(0.3) : const Color(0xFFF6DDB7))
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Opacity(
                      opacity: unlocked ? 1.0 : 0.45,
                      child: Text(
                        badge['icon'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: unlocked
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white30 : Colors.black38),
                          ),
                        ),
                        Text(
                          badge['subtitle'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: unlocked
                                ? (isDark ? Colors.white60 : Colors.black54)
                                : (isDark ? Colors.white24 : Colors.black26),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unlocked)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 20,
                    )
                  else
                    const Icon(
                      Icons.lock_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
