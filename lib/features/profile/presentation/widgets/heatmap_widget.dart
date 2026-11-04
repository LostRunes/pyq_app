import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/features/utilities/presentation/providers/activity_providers.dart';

class StudyActivityHeatmap extends ConsumerWidget {
  const StudyActivityHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);
    final streak = ref.watch(streakProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark
        ? const Color(0xFF1A1A2E).withOpacity(0.9)
        : Colors.white;

    final borderThemeColor = isDark
        ? const Color(0xFF6366F1).withOpacity(0.15)
        : Colors.indigo.withOpacity(0.1);

    // Calculate dates for the last 15 weeks (15 columns x 7 days = 105 days)
    // We end on today, align columns by week starting on Sunday/Monday
    final today = DateTime.now();
    // Start date is 15 weeks ago, aligned to the start of the week
    final startOffset = today.weekday - 1; // days since Monday
    final totalDays = 15 * 7;
    final startDate = today.subtract(Duration(days: totalDays - 1 + startOffset));

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth > 550;

        final heatmapCard = Expanded(
          flex: useRow ? 2 : 0,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderThemeColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Study Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'This Year',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Heatmap Grid Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Labels (M, W, F)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        _buildDayLabel('M', isDark),
                        const SizedBox(height: 14),
                        _buildDayLabel('W', isDark),
                        const SizedBox(height: 14),
                        _buildDayLabel('F', isDark),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Grid blocks
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(15, (weekIdx) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Column(
                                children: List.generate(7, (dayIdx) {
                                  final dayOffset = weekIdx * 7 + dayIdx;
                                  final currentDay = startDate.add(Duration(days: dayOffset));
                                  final dateStr = _formatDate(currentDay);
                                  final count = activity[dateStr] ?? 0;

                                  // Disable future dates
                                  final isFuture = currentDay.isAfter(today);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Tooltip(
                                      message: '${currentDay.day}/${currentDay.month} : $count active',
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: isFuture
                                              ? Colors.transparent
                                              : _getHeatmapColor(count, isDark),
                                          borderRadius: BorderRadius.circular(2.5),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Less',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildLegendBlock(0, isDark),
                    _buildLegendBlock(1, isDark),
                    _buildLegendBlock(2, isDark),
                    _buildLegendBlock(3, isDark),
                    _buildLegendBlock(4, isDark),
                    const SizedBox(width: 4),
                    Text(
                      'More',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        final streakCard = Container(
          padding: const EdgeInsets.all(18),
          width: useRow ? 140 : double.infinity,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderThemeColor, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$streak',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 28),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Day Streak',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                'Keep it up!',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        );

        if (useRow) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heatmapCard,
              const SizedBox(width: 16),
              streakCard,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heatmapCard,
              const SizedBox(height: 16),
              streakCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildDayLabel(String text, bool isDark) {
    return SizedBox(
      height: 10,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 8,
          color: isDark ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLegendBlock(int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _getHeatmapColor(count, isDark),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Color _getHeatmapColor(int count, bool isDark) {
    if (isDark) {
      if (count <= 0) return const Color(0xFF1E1B4B).withOpacity(0.3);
      if (count == 1) return const Color(0xFF818CF8).withOpacity(0.35);
      if (count == 2) return const Color(0xFF6366F1).withOpacity(0.65);
      if (count == 3) return const Color(0xFF6366F1);
      return const Color(0xFFC0A6FF);
    } else {
      if (count <= 0) return Colors.grey.withOpacity(0.12);
      if (count == 1) return Colors.indigo.withOpacity(0.2);
      if (count == 2) return Colors.indigo.withOpacity(0.45);
      if (count == 3) return Colors.indigo.withOpacity(0.75);
      return Colors.indigo;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
