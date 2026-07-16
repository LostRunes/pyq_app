import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import '../providers/aptitude_providers.dart';

class AptitudeTopicsScreen extends ConsumerWidget {
  const AptitudeTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topics = [
      {
        'title': 'Mixture & Alligation',
        'endpoint': 'MixtureAndAlligation',
        'desc': 'Ratios, mixing components, and concentration rules.',
        'icon': Icons.opacity_rounded,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Profit & Loss',
        'endpoint': 'ProfitAndLoss',
        'desc': 'Calculate margins, markups, discounts, and selling prices.',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Pipes & Cisterns',
        'endpoint': 'PipesAndCistern',
        'desc': 'Flow rates, filling times, and leak calculations.',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Ages',
        'endpoint': 'Age',
        'desc': 'Solve linear equations relating to age ratios and differences.',
        'icon': Icons.hourglass_empty_rounded,
        'color': const Color(0xFFEC4899),
      },
      {
        'title': 'Permutation & Combination',
        'endpoint': 'PermutationAndCombination',
        'desc': 'Arrangements, selections, probability, and factorials.',
        'icon': Icons.functions_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Speed, Time & Distance',
        'endpoint': 'SpeedTimeDistance',
        'desc': 'Relative speed, average speed, trains, and race tracks.',
        'icon': Icons.speed_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Simple Interest',
        'endpoint': 'SimpleInterest',
        'desc': 'Principal, interest rates, timelines, and compound values.',
        'icon': Icons.percent_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Calendars',
        'endpoint': 'Calendar',
        'desc': 'Determine weekdays, leap years, and calendar cycles.',
        'icon': Icons.calendar_today_rounded,
        'color': const Color(0xFF14B8A6),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0C20) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF171330) : theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aptitude Topics',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInSlide(
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF0F0C20)]
                        : [const Color(0xFFEDE9FE), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantitative Aptitude',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose a topic below to test and improve your arithmetic and logical skills.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.psychology_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cumulative Stats Dashboard (Like the Bee Dashboard stats)
            Consumer(
              builder: (context, ref, child) {
                final stats = ref.watch(aptitudeStatsProvider);
                final totalSolved = stats.totalSolved;
                final totalScore = stats.totalScore;
                final accuracy = totalSolved > 0 
                    ? (stats.correctCount / totalSolved * 100).toStringAsFixed(1) 
                    : '0';

                return FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B4B).withOpacity(0.4) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white10 : theme.colorScheme.primary.withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          label: 'Total Score',
                          value: '${totalScore >= 0 ? "+" : ""}$totalScore pts',
                          valueColor: totalScore >= 0 ? Colors.green : Colors.redAccent,
                          icon: Icons.emoji_events_rounded,
                          iconColor: Colors.amber,
                        ),
                        Container(
                          width: 1.5,
                          height: 40,
                          color: isDark ? Colors.white10 : Colors.grey[200],
                        ),
                        _buildStatItem(
                          context,
                          label: 'Solved',
                          value: '$totalSolved',
                          valueColor: theme.colorScheme.primary,
                          icon: Icons.check_circle_rounded,
                          iconColor: theme.colorScheme.primary,
                        ),
                        Container(
                          width: 1.5,
                          height: 40,
                          color: isDark ? Colors.white10 : Colors.grey[200],
                        ),
                        _buildStatItem(
                          context,
                          label: 'Accuracy',
                          value: '$accuracy%',
                          valueColor: const Color(0xFF10B981),
                          icon: Icons.insights_rounded,
                          iconColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topics.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final topic = topics[index];
                final Color topicColor = topic['color'] as Color;

                return Consumer(
                  builder: (context, ref, child) {
                    final stats = ref.watch(aptitudeStatsProvider);
                    final solvedCount = stats.getSolvedCountForTopic(topic['endpoint'] as String);
                    final topicScore = stats.getScoreForTopic(topic['endpoint'] as String);

                    return FadeInSlide(
                      delay: Duration(milliseconds: index * 50),
                      duration: const Duration(milliseconds: 400),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/aptitude_questions',
                            arguments: {
                              'title': topic['title'],
                              'endpoint': topic['endpoint'],
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.03)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : topicColor.withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: topicColor.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left side color block containing the icon
                                  Container(
                                    width: 80,
                                    color: topicColor.withOpacity(0.12),
                                    child: Center(
                                      child: Icon(
                                        topic['icon'] as IconData,
                                        color: topicColor,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  // Right side content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            topic['title'] as String,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            topic['desc'] as String,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: isDark ? Colors.white54 : Colors.black54,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          const Divider(height: 1, thickness: 1),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_outline_rounded,
                                                    size: 14,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Solved: $solvedCount',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.emoji_events_outlined,
                                                    size: 14,
                                                    color: topicScore >= 0 ? Colors.green : Colors.redAccent,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${topicScore >= 0 ? "+" : ""}$topicScore pts',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: topicScore >= 0 ? Colors.green : Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
