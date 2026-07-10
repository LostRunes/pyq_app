import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import '../../data/models/aptitude_question.dart';
import '../providers/aptitude_providers.dart';

class AptitudeQuestionDetailScreen extends ConsumerStatefulWidget {
  const AptitudeQuestionDetailScreen({super.key});

  @override
  ConsumerState<AptitudeQuestionDetailScreen> createState() =>
      _AptitudeQuestionDetailScreenState();
}

class _AptitudeQuestionDetailScreenState
    extends ConsumerState<AptitudeQuestionDetailScreen> {
  late List<AptitudeQuestion> _questions;
  late int _currentIndex;
  late String _title;
  late String _endpoint;
  bool _initialized = false;

  String? _selectedOption;
  bool _isAnswered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _questions = args['questions'] as List<AptitudeQuestion>;
      _currentIndex = args['initialIndex'] as int? ?? 0;
      _title = args['title'] ?? 'Question';
      _endpoint = args['endpoint'] ?? '';
      _initialized = true;

      // Restore previously saved answer if present
      final stats = ref.read(aptitudeStatsProvider);
      final savedAns = stats.answers[_questions[_currentIndex].question];
      if (savedAns != null) {
        _selectedOption = savedAns['selectedOption'];
        _isAnswered = true;
      }
    }
  }

  void _selectOption(String option) {
    if (_isAnswered) return;
    
    final question = _questions[_currentIndex];
    final isCorrectAns = _isOptionCorrect(option, question.answer);

    ref.read(aptitudeStatsProvider.notifier).recordAnswer(
      topicEndpoint: _endpoint,
      questionText: question.question,
      selectedOption: option,
      isCorrect: isCorrectAns,
    );

    setState(() {
      _selectedOption = option;
      _isAnswered = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        final stats = ref.read(aptitudeStatsProvider);
        final savedAns = stats.answers[_questions[_currentIndex].question];
        if (savedAns != null) {
          _selectedOption = savedAns['selectedOption'];
          _isAnswered = true;
        } else {
          _selectedOption = null;
          _isAnswered = false;
        }
      });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        final stats = ref.read(aptitudeStatsProvider);
        final savedAns = stats.answers[_questions[_currentIndex].question];
        if (savedAns != null) {
          _selectedOption = savedAns['selectedOption'];
          _isAnswered = true;
        } else {
          _selectedOption = null;
          _isAnswered = false;
        }
      });
    }
  }

  bool _isOptionCorrect(String option, String answer) {
    return option.trim().toLowerCase() == answer.trim().toLowerCase();
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
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
            const SizedBox(height: 24),

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
                    'QUESTION ${_currentIndex + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B5CF6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.question,
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

            // Options List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final option = question.options[index];
                final isSelected = _selectedOption == option;
                final isCorrectAns = _isOptionCorrect(option, question.answer);

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
                  borderColor = const Color(0xFF8B5CF6);
                  bgColor = const Color(0xFF8B5CF6).withOpacity(isDark ? 0.15 : 0.08);
                }

                // Prefix letter (A, B, C, D)
                final prefix = String.fromCharCode(65 + index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => _selectOption(option),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (isCorrectAns && _isAnswered) ? 2.0 : 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : isDark
                                      ? Colors.white10
                                      : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              prefix,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : isDark
                                        ? Colors.white70
                                        : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (trailingIcon != null) trailingIcon,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Explanation (appears when answered)
            if (_isAnswered) ...[
              const SizedBox(height: 16),
              FadeInSlide(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.06 : 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Explanation',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.explanation ?? 'No explanation available.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Prev button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentIndex > 0 ? _prevQuestion : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: _currentIndex > 0
                            ? const Color(0xFF8B5CF6)
                            : Colors.grey.withOpacity(0.3),
                      ),
                      foregroundColor: const Color(0xFF8B5CF6),
                      disabledForegroundColor: Colors.grey.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Next button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentIndex < _questions.length - 1 ? _nextQuestion : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                      disabledForegroundColor: Colors.grey.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
