import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import '../providers/gate_providers.dart';
import '../../data/models/gate_question.dart';

class GateQuestionDetailScreen extends ConsumerStatefulWidget {
  const GateQuestionDetailScreen({super.key});

  @override
  ConsumerState<GateQuestionDetailScreen> createState() =>
      _GateQuestionDetailScreenState();
}

class _GateQuestionDetailScreenState extends ConsumerState<GateQuestionDetailScreen> {
  late List<GateQuestion> _questions;
  late int _currentIndex;
  late String _title;
  late String _id;
  bool _initialized = false;

  // State for MCQ questions
  String? _selectedOptionText;

  // State for NAT questions
  final TextEditingController _natController = TextEditingController();
  String? _submittedNatAnswer;

  bool _isAnswered = false;

  @override
  void dispose() {
    _natController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _questions = args['questions'] as List<GateQuestion>;
      _currentIndex = args['initialIndex'] as int? ?? 0;
      _title = args['title'] ?? 'Question';
      _id = args['id'] ?? '';
      _initialized = true;

      _loadSavedAnswer();
    }
  }

  void _loadSavedAnswer() {
    final question = _questions[_currentIndex];
    final stats = ref.read(gateStatsProvider);
    final savedAns = stats.answers[question.id];

    if (savedAns != null) {
      final String answerStr = savedAns['selectedAnswer'] ?? '';
      if (question.questionType == 'MCQ') {
        _selectedOptionText = answerStr;
      } else {
        _submittedNatAnswer = answerStr;
        _natController.text = answerStr;
      }
      _isAnswered = true;
    } else {
      _selectedOptionText = null;
      _submittedNatAnswer = null;
      _natController.clear();
      _isAnswered = false;
    }
  }

  void _selectMCQOption(GateOption option) {
    if (_isAnswered) return;

    final question = _questions[_currentIndex];
    final isCorrectAns = option.isCorrect;

    ref.read(gateStatsProvider.notifier).recordAnswer(
          questionId: question.id,
          selectedAnswer: option.optionText,
          isCorrect: isCorrectAns,
          marks: question.marks,
        );

    setState(() {
      _selectedOptionText = option.optionText;
      _isAnswered = true;
    });
  }

  void _submitNATAnswer() {
    final input = _natController.text.trim();
    if (input.isEmpty || _isAnswered) return;

    final question = _questions[_currentIndex];
    final correctAnsStr = question.correctAnswerText ?? '';

    // Simple comparison: check if strings match exactly (lowercase, trimmed)
    final isCorrect = input.toLowerCase() == correctAnsStr.toLowerCase();

    ref.read(gateStatsProvider.notifier).recordAnswer(
          questionId: question.id,
          selectedAnswer: input,
          isCorrect: isCorrect,
          marks: question.marks,
        );

    setState(() {
      _submittedNatAnswer = input;
      _isAnswered = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _loadSavedAnswer();
      });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadSavedAnswer();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    // Difficulty color
    Color difficultyColor = Colors.grey;
    if (question.difficulty == 'easy') {
      difficultyColor = Colors.green;
    } else if (question.difficulty == 'medium') {
      difficultyColor = Colors.orange;
    } else if (question.difficulty == 'hard') {
      difficultyColor = Colors.red;
    }

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
          _title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentIndex + 1}/${_questions.length}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (question.occurrences.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${question.occurrences.first.exam} ${question.occurrences.first.year}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  if (question.occurrences.first.questionNumber.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Q${question.occurrences.first.questionNumber}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: difficultyColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    question.difficulty.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: difficultyColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${question.marks} Mark${question.marks > 1 ? "s" : ""}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    question.questionType,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.occurrences.isNotEmpty
                        ? 'QUESTION ${_currentIndex + 1} • ${question.occurrences.first.exam} ${question.occurrences.first.year}'
                        : 'QUESTION ${_currentIndex + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF10B981),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.questionText,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // MCQ vs NAT options rendering
            if (question.questionType == 'MCQ') ...[
              // MCQ options list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final isSelected = _selectedOptionText == option.optionText;
                  final isCorrectAns = option.isCorrect;

                  Color borderColor = isDark ? Colors.white10 : Colors.grey[200]!;
                  Color bgColor = isDark ? Colors.white.withOpacity(0.02) : Colors.white;
                  Widget? trailingIcon;

                  if (_isAnswered) {
                    if (isCorrectAns) {
                      borderColor = Colors.green;
                      bgColor = Colors.green.withOpacity(isDark ? 0.15 : 0.08);
                      trailingIcon = const Icon(Icons.check_circle_rounded, color: Colors.green);
                    } else if (isSelected) {
                      borderColor = Colors.red;
                      bgColor = Colors.red.withOpacity(isDark ? 0.15 : 0.08);
                      trailingIcon = const Icon(Icons.cancel_rounded, color: Colors.red);
                    }
                  } else if (isSelected) {
                    borderColor = const Color(0xFF10B981);
                    bgColor = const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08);
                  }

                  Color textColor = isDark ? Colors.white70 : Colors.black87;
                  Color prefixColor = isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87);
                  Color prefixBgColor = isSelected
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!);

                  if (_isAnswered) {
                    if (isCorrectAns) {
                      textColor = Colors.green;
                      prefixColor = Colors.white;
                      prefixBgColor = Colors.green;
                    } else if (isSelected) {
                      textColor = Colors.red;
                      prefixColor = Colors.white;
                      prefixBgColor = Colors.red;
                    }
                  } else if (isSelected) {
                    textColor = const Color(0xFF10B981);
                  }

                  final prefix = option.optionLabel.isNotEmpty
                      ? option.optionLabel
                      : String.fromCharCode(65 + index);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => _selectMCQOption(option),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: prefixBgColor,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                prefix,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: prefixColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option.optionText,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (trailingIcon != null) ...[
                              const SizedBox(width: 10),
                              trailingIcon,
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              // NAT text box
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Numerical Answer Type',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _natController,
                      enabled: !_isAnswered,
                      decoration: InputDecoration(
                        hintText: 'Enter your answer here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _isAnswered
                            ? (_submittedNatAnswer?.toLowerCase() ==
                                    (question.correctAnswerText ?? '').toLowerCase()
                                ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                                : const Icon(Icons.cancel_rounded, color: Colors.red))
                            : null,
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    if (!_isAnswered)
                      ElevatedButton(
                        onPressed: _submitNATAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Submit Answer',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Explanation & Concepts
            if (_isAnswered) ...[
              const SizedBox(height: 24),
              FadeInSlide(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            'Explanation & Correct Answer',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (question.correctAnswerText != null) ...[
                        Text(
                          'Correct Answer: ${question.correctAnswerText}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        question.explanation ?? 'No explanation provided.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Concepts & Tags chips
            if (question.concepts.isNotEmpty || question.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Associated Tags & Concepts',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...question.concepts.map((concept) => Chip(
                        label: Text(
                          concept,
                          style: GoogleFonts.outfit(fontSize: 11),
                        ),
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                      )),
                  ...question.tags.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: GoogleFonts.outfit(fontSize: 11),
                        ),
                        backgroundColor: theme.colorScheme.secondary.withOpacity(0.05),
                      )),
                ],
              ),
            ],

            const SizedBox(height: 40),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex > 0 ? _prevQuestion : null,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Previous',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentIndex < _questions.length - 1 ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
