import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import '../providers/gate_providers.dart';
import '../../data/models/gate_question.dart';

class GateQuestionsScreen extends ConsumerWidget {
  const GateQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String title = args['title'] ?? 'GATE Practice';
    final String type = args['type'] ?? 'topic'; // 'topic' or 'paper'
    final String id = (type == 'topic') ? (args['topicId'] ?? '') : (args['paperId'] ?? '');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final questionsAsync = type == 'topic'
        ? ref.watch(gateQuestionsByTopicProvider(id))
        : ref.watch(gateQuestionsByPaperProvider(id));

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
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading questions: $err',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 72,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No questions available yet.',
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

          final stats = ref.watch(gateStatsProvider);

          int solvedCount = 0;
          double topicScore = 0;
          for (final q in questions) {
            final ans = stats.answers[q.id];
            if (ans != null) {
              solvedCount++;
              final rawIsCorrect = ans['isCorrect'];
              final bool isCorrect = rawIsCorrect is bool
                  ? rawIsCorrect
                  : (rawIsCorrect is num ? rawIsCorrect > 0 : false);
              final marks = (ans['marks'] as num?)?.toDouble() ?? 1.0;
              if (isCorrect) {
                topicScore += marks;
              } else {
                topicScore -= (marks / 3.0);
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInSlide(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    'Select a Question',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInSlide(
                  delay: const Duration(milliseconds: 50),
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    'Tap a question number below to practice. Navigate through them sequentially inside the viewer.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats card
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Solved Questions',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$solvedCount / ${questions.length}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Calculated Score',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${topicScore >= 0 ? "+" : ""}${topicScore.toStringAsFixed(2)} pts',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: topicScore >= 0 ? Colors.green : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'GATE Scoring Rules: +Marks for correct, -1/3 of marks for incorrect MCQ. No penalty for NAT.',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final ans = stats.answers[question.id];
                    final rawIsCorrect = ans != null ? ans['isCorrect'] : null;
                    final bool? isCorrect = rawIsCorrect == null
                        ? null
                        : (rawIsCorrect is bool
                            ? rawIsCorrect
                            : (rawIsCorrect is num ? rawIsCorrect > 0 : null));

                    Color blockColor = isDark ? Colors.white.withOpacity(0.04) : Colors.white;
                    Color borderColor = isDark ? Colors.white10 : theme.colorScheme.primary.withOpacity(0.15);
                    Color textColor = isDark ? Colors.white : Colors.black87;

                    if (isCorrect == true) {
                      blockColor = Colors.green.withOpacity(isDark ? 0.2 : 0.1);
                      borderColor = Colors.green;
                      textColor = Colors.green;
                    } else if (isCorrect == false) {
                      blockColor = Colors.red.withOpacity(isDark ? 0.2 : 0.1);
                      borderColor = Colors.red;
                      textColor = Colors.red;
                    }

                    return FadeInSlide(
                      delay: Duration(milliseconds: (index % 20) * 15),
                      duration: const Duration(milliseconds: 350),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/gate_question_detail',
                            arguments: {
                              'questions': questions,
                              'initialIndex': index,
                              'title': title,
                              'id': id,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: blockColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Q${index + 1}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
