import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import '../providers/gate_providers.dart';

class GateYearAnalysisScreen extends ConsumerWidget {
  const GateYearAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String subjectId = args['subjectId'] ?? '';
    final String subjectName = args['subjectName'] ?? 'GATE Subject';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final analysisAsync = ref.watch(gateYearAnalysisProvider(subjectId));

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
          '$subjectName Analysis',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: analysisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load year analysis: $err',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 72,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No year analysis data available yet.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          int total1M = 0;
          int total2M = 0;
          int totalMarksAll = 0;
          int maxMarks = 0;

          for (final r in records) {
            final m1 = (r['one_mark_questions'] as int?) ?? 0;
            final m2 = (r['two_mark_questions'] as int?) ?? 0;
            final tm = (r['total_marks'] as int?) ?? 0;

            total1M += m1;
            total2M += m2;
            totalMarksAll += tm;
            if (tm > maxMarks) maxMarks = tm;
          }

          final double avgMarks = records.isNotEmpty ? totalMarksAll / records.length : 0.0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(gateYearAnalysisProvider(subjectId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                FadeInSlide(
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GATE Year-wise Analysis',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Detailed weightage breakdown of $subjectName across past exam papers.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Top stats summary card
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatTile('Total Papers', '${records.length}', theme),
                        Container(height: 30, width: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                        _buildStatTile('Avg Weightage', '${avgMarks.toStringAsFixed(1)} pts', theme),
                        Container(height: 30, width: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                        _buildStatTile('Max Weightage', '$maxMarks pts', theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Table Container Card
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  duration: const Duration(milliseconds: 400),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'Paper / Year',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '1M Qs',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '2M Qs',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Total Marks',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Table Rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: records.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: theme.colorScheme.onSurface.withOpacity(0.06),
                            ),
                            itemBuilder: (context, index) {
                              final item = records[index];
                              final paper = item['gate_papers'] as Map<String, dynamic>? ?? {};
                              final year = paper['year'] as int? ?? 0;
                              final setNum = paper['set_number'] as int?;
                              final m1 = (item['one_mark_questions'] as int?) ?? 0;
                              final m2 = (item['two_mark_questions'] as int?) ?? 0;
                              final totalMarks = (item['total_marks'] as int?) ?? 0;

                              final paperLabel = setNum != null ? 'GATE $year (Set $setNum)' : 'GATE $year';

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        paperLabel,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$m1',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(fontSize: 13.5),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$m2',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(fontSize: 13.5),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$totalMarks pts',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatTile(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
