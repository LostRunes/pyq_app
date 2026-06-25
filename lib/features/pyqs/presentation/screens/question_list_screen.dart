import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focus_fox/features/pyqs/data/models/question.dart';
import 'package:focus_fox/features/pyqs/presentation/providers/pyq_providers.dart';
import 'package:focus_fox/services/pdf_service.dart';
import 'package:focus_fox/shared/widgets/loading_overlay.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;
  const QuestionListScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  String? _selectedType;
  String? _difficultySort;
  String? _yearSort;
  String? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider(widget.topicId));
    final isLoading = ref.watch(pdfLoadingProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Download PDF',
            onPressed: isLoading
                ? null
                : () async {
                    ref.read(pdfLoadingProvider.notifier).setLoading(true);

                    try {
                      final fullQuestions = await ref.read(
                        topicPdfDataProvider(widget.topicId).future,
                      );

                      final pdfService = PdfService();
                      final pdfBytes = await pdfService.generateTopicPdf(
                        widget.topicName,
                        fullQuestions,
                      );

                      await pdfService.downloadPdf(
                        pdfBytes,
                        '${widget.topicName.replaceAll(' ', '_')}_Questions.pdf',
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      ref.read(pdfLoadingProvider.notifier).setLoading(false);
                    }
                  },
          ),
        ],
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
            : null,
        child: SafeArea(
          child: Stack(
            children: [
              questionsAsync.when(
                data: (questions) {
                  final List<String> availableYears =
                      questions
                          .expand((q) => q.pyqSources.map((s) => s.year))
                          .where((y) => y.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort((a, b) => b.compareTo(a));

                  // Apply filtering
                  List<Question> filteredQuestions = List<Question>.from(
                    questions,
                  );

                  if (_selectedType != null) {
                    filteredQuestions = filteredQuestions.where((q) {
                      return q.pyqSources.any(
                        (s) =>
                            s.examType.toLowerCase() ==
                            _selectedType!.toLowerCase(),
                      );
                    }).toList();
                  }

                  if (_selectedYear != null) {
                    filteredQuestions = filteredQuestions.where((q) {
                      return q.pyqSources.any((s) => s.year == _selectedYear);
                    }).toList();
                  }

                  // Helper for difficulty mapping
                  int getDifficultyValue(String difficulty) {
                    switch (difficulty.toLowerCase()) {
                      case 'easy':
                        return 1;
                      case 'medium':
                        return 2;
                      case 'hard':
                        return 3;
                      default:
                        return 0;
                    }
                  }

                  // Apply difficulty sorting
                  if (_difficultySort != null) {
                    filteredQuestions.sort((a, b) {
                      final valA = getDifficultyValue(a.difficulty);
                      final valB = getDifficultyValue(b.difficulty);
                      if (_difficultySort == 'Easy to Hard') {
                        return valA.compareTo(valB);
                      } else {
                        return valB.compareTo(valA);
                      }
                    });
                  }

                  // Apply year sorting
                  if (_yearSort != null) {
                    filteredQuestions.sort((a, b) {
                      final yearA = a.pyqSources.isNotEmpty
                          ? (int.tryParse(a.pyqSources.first.year) ?? 0)
                          : 0;
                      final yearB = b.pyqSources.isNotEmpty
                          ? (int.tryParse(b.pyqSources.first.year) ?? 0)
                          : 0;
                      if (_yearSort == 'Ascending') {
                        return yearA.compareTo(yearB);
                      } else {
                        return yearB.compareTo(yearA);
                      }
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          widget.topicName,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Horizontal Filter Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            _buildActionPill(
                              context: context,
                              label: 'All',
                              isActive:
                                  _selectedType == null &&
                                  _difficultySort == null &&
                                  _yearSort == null &&
                                  _selectedYear == null,
                              onTap: () {
                                setState(() {
                                  _selectedType = null;
                                  _difficultySort = null;
                                  _yearSort = null;
                                  _selectedYear = null;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                setState(() {
                                  _selectedType = value == 'None'
                                      ? null
                                      : value;
                                });
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'Midsem',
                                  child: Text('Midsem'),
                                ),
                                const PopupMenuItem(
                                  value: 'Endsem',
                                  child: Text('Endsem'),
                                ),
                                const PopupMenuItem(
                                  value: 'None',
                                  child: Text('None (Reset)'),
                                ),
                              ],
                              child: _buildFilterPill(
                                context: context,
                                label: _selectedType ?? 'Type',
                                isActive: _selectedType != null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                setState(() {
                                  _difficultySort = value == 'None'
                                      ? null
                                      : value;
                                });
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'Easy to Hard',
                                  child: Text('Easy to Hard'),
                                ),
                                const PopupMenuItem(
                                  value: 'Hard to Easy',
                                  child: Text('Hard to Easy'),
                                ),
                                const PopupMenuItem(
                                  value: 'None',
                                  child: Text('None (Reset)'),
                                ),
                              ],
                              child: _buildFilterPill(
                                context: context,
                                label: _difficultySort ?? 'Difficulty',
                                isActive: _difficultySort != null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                setState(() {
                                  if (value == 'Ascending' ||
                                      value == 'Descending') {
                                    _yearSort = value;
                                  } else if (value == 'None') {
                                    _yearSort = null;
                                    _selectedYear = null;
                                  } else {
                                    _selectedYear = value;
                                  }
                                });
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'Ascending',
                                  child: Text('Sort: Oldest First (Ascending)'),
                                ),
                                const PopupMenuItem(
                                  value: 'Descending',
                                  child: Text(
                                    'Sort: Newest First (Descending)',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'None',
                                  child: Text('None (Reset)'),
                                ),
                                if (availableYears.isNotEmpty) ...[
                                  const PopupMenuDivider(),
                                  ...availableYears.map(
                                    (yr) => PopupMenuItem(
                                      value: yr,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(yr),
                                          if (_selectedYear == yr) ...[
                                            const Spacer(),
                                            const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              child: _buildFilterPill(
                                context: context,
                                label: _selectedYear != null
                                    ? 'Year: $_selectedYear'
                                    : (_yearSort ?? 'Year'),
                                isActive:
                                    _selectedYear != null || _yearSort != null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filteredQuestions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/sad_raccoon.png',
                                        height: 130,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No questions match the selected filters.',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                itemCount: filteredQuestions.length,
                                itemBuilder: (context, i) {
                                  final question = filteredQuestions[i];
                                  final firstSource =
                                      question.pyqSources.isNotEmpty
                                      ? question.pyqSources.first
                                      : null;

                                  String qNum = '';
                                  String examInfo = '';
                                  if (firstSource != null) {
                                    qNum = firstSource.questionNumber.trim();
                                    if (qNum.isNotEmpty) {
                                      if (RegExp(r'^\d+$').hasMatch(qNum)) {
                                        qNum = 'Q. $qNum';
                                      } else if (!qNum.toLowerCase().startsWith(
                                        'q',
                                      )) {
                                        qNum = 'Q. $qNum';
                                      }
                                    }

                                    if (firstSource.examType.isNotEmpty &&
                                        firstSource.year.isNotEmpty) {
                                      examInfo =
                                          '${firstSource.examType} ${firstSource.year}';
                                    } else if (firstSource.year.isNotEmpty) {
                                      examInfo = firstSource.year;
                                    } else if (firstSource
                                        .examType
                                        .isNotEmpty) {
                                      examInfo = firstSource.examType;
                                    }
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/question_detail',
                                          arguments: {
                                            'questionId': question.id,
                                          },
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(28),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.05),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: 6,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    children: [
                                                      if (qNum.isNotEmpty)
                                                        _buildTag(
                                                          context,
                                                          qNum,
                                                          theme
                                                              .colorScheme
                                                              .tertiary
                                                              .withOpacity(0.2),
                                                          theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.6),
                                                        ),
                                                      if (examInfo.isNotEmpty)
                                                        _buildTag(
                                                          context,
                                                          examInfo,
                                                          theme
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(0.1),
                                                          theme
                                                              .colorScheme
                                                              .primary,
                                                        ),
                                                      _buildTag(
                                                        context,
                                                        question.difficulty
                                                            .toUpperCase(),
                                                        _getDifficultyColor(
                                                          question.difficulty,
                                                        ).withOpacity(0.1),
                                                        _getDifficultyColor(
                                                          question.difficulty,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.3),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              question.questionText,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.4,
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
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              if (isLoading)
                const LoadingOverlay(message: 'Preparing your topic PDF... ✨'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : theme.colorScheme.primary.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Colors.white
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required BuildContext context,
    required String label,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : theme.colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? Colors.white
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: isActive
                ? Colors.white
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade400;
      case 'medium':
        return Colors.orange.shade400;
      case 'hard':
        return Colors.red.shade400;
      default:
        return Colors.blue.shade400;
    }
  }
}
