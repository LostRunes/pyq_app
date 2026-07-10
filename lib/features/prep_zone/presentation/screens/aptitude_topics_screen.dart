import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';

class AptitudeTopicsScreen extends StatelessWidget {
  const AptitudeTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 28),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                final Color topicColor = topic['color'] as Color;

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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: topicColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              topic['icon'] as IconData,
                              color: topicColor,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            topic['title'] as String,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topic['desc'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
