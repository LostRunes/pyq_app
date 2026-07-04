import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/core/providers.dart';
import 'package:focus_fox/features/pyqs/presentation/providers/pyq_providers.dart';
import 'leetcode_webview_screen.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/solution_viewer_screen.dart';

class AlgoCodeScreen extends ConsumerStatefulWidget {
  const AlgoCodeScreen({super.key});

  @override
  ConsumerState<AlgoCodeScreen> createState() => _AlgoCodeScreenState();
}

class _AlgoCodeScreenState extends ConsumerState<AlgoCodeScreen> {
  String? _selectedTopic;
  bool _isLoadingQuestions = false;
  String? _fetchError;
  List<Map<String, dynamic>> _questions = [];

  // Topics matching database parent_topic and screenshot 1
  final List<Map<String, dynamic>> _topics = [
    {'name': 'Array', 'icon': Icons.grid_on_rounded},
    {'name': 'Searching', 'icon': Icons.search_rounded},
    {'name': 'Recursion', 'icon': Icons.refresh_rounded},
    {'name': 'String', 'icon': Icons.notes_rounded},
    {'name': 'Stack', 'icon': Icons.layers_rounded},
    {'name': 'Queue', 'icon': Icons.format_list_bulleted_rounded},
    {'name': 'Linked List', 'icon': Icons.link_rounded},
    {'name': 'Tree', 'icon': Icons.account_tree_rounded},
    {'name': 'Graph', 'icon': Icons.hub_rounded},
  ];

  Future<void> _fetchQuestions(String topic) async {
    // Set all state atomically before the async gap
    setState(() {
      _isLoadingQuestions = true;
      _fetchError = null;
      _questions = [];
    });

    try {
      final supabase = ref.read(supabase1ClientProvider);
      final response = await supabase
          .from('leetcode')
          .select(
            'id, parent_topic, difficulty, question_name, question_link, priority_order',
          )
          .eq('parent_topic', topic)
          .order('priority_order', ascending: true);

      if (mounted) {
        final parsed = (response as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        debugPrint('Fetched ${parsed.length} questions for $topic');
        setState(() {
          _questions = parsed;
          _isLoadingQuestions = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error fetching questions: $e\n$st');
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _isLoadingQuestions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0C20)
          : theme.scaffoldBackgroundColor,
      appBar: _selectedTopic == null
          ? null
          : AppBar(
              backgroundColor: isDark
                  ? const Color(0xFF171330)
                  : theme.appBarTheme.backgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  setState(() {
                    _selectedTopic = null;
                  });
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTopic!,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Sorted by difficulty — Easy • Medium • Hard',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              actions: const [SizedBox(width: 16)],
            ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: SafeArea(
          child: _selectedTopic == null
              ? _buildTopicSelectionScreen(isDark)
              : _buildQuestionListScreen(isDark),
        ),
      ),
    );
  }

  // SCREEN 1: Topic Selection
  Widget _buildTopicSelectionScreen(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Choose a Topic',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Text(
            'Select a data structure or algorithm to practice LeetCode questions',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _topics.length,
            itemBuilder: (context, index) {
              final topic = _topics[index];
              return InkWell(
                onTap: () {
                  // Set topic AND loading state together to avoid empty list flash
                  setState(() {
                    _selectedTopic = topic['name'];
                    _isLoadingQuestions = true;
                    _fetchError = null;
                    _questions = [];
                  });
                  _fetchQuestions(topic['name']);
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1B4B).withOpacity(0.3)
                        : Colors.indigo.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF6366F1).withOpacity(0.15)
                          : Colors.indigo.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF312E81).withOpacity(0.5)
                              : Colors.indigo.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          topic['icon'] as IconData,
                          color: const Color(0xFF818CF8),
                          size: 24,
                        ),
                      ),
                      Text(
                        topic['name'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // SCREEN 2: Question List columns by difficulty (Easy, Medium, Hard)
  Widget _buildQuestionListScreen(bool isDark) {
    final easyQuestions = _questions
        .where((q) => q['difficulty'].toString().toLowerCase() == 'easy')
        .toList();
    final mediumQuestions = _questions
        .where((q) => q['difficulty'].toString().toLowerCase() == 'medium')
        .toList();
    final hardQuestions = _questions
        .where((q) => q['difficulty'].toString().toLowerCase() == 'hard')
        .toList();

    return _isLoadingQuestions
        ? const Center(child: CircularProgressIndicator())
        : _fetchError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load questions',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fetchError!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _fetchQuestions(_selectedTopic!),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final useHorizontalScroll = constraints.maxWidth < 700;

              final content = [
                _buildDifficultyColumn(
                  title: 'Easy',
                  count: easyQuestions.length,
                  questions: easyQuestions,
                  accentColor: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                _buildDifficultyColumn(
                  title: 'Medium',
                  count: mediumQuestions.length,
                  questions: mediumQuestions,
                  accentColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
                _buildDifficultyColumn(
                  title: 'Hard',
                  count: hardQuestions.length,
                  questions: hardQuestions,
                  accentColor: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ];

              if (useHorizontalScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content
                        .map(
                          (col) => SizedBox(
                            width: constraints.maxWidth * 0.85,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: SingleChildScrollView(child: col),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content
                        .map(
                          (col) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: SingleChildScrollView(child: col),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              }
            },
          );
  }

  Widget _buildDifficultyColumn({
    required String title,
    required int count,
    required List<Map<String, dynamic>> questions,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171330).withOpacity(0.4)
            : Colors.indigo.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Border accent top line
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$count questions',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final qId = q['id'].toString();
              return Consumer(
                builder: (context, ref, child) {
                  final isCompleted = ref.watch(leetCodeProgressProvider)[qId] ?? false;
                  return ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isCompleted,
                          onChanged: (val) {
                            ref.read(leetCodeProgressProvider.notifier).toggleProgress(qId);
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          activeColor: const Color(0xFF6366F1),
                        ),
                        Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      q['question_name'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    onTap: () => _showOptionsModal(q),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // SCREEN 3: Options Modal
  void _showOptionsModal(Map<String, dynamic> question) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if solution exists
    bool solutionExists = false;
    try {
      final supabase = ref.read(supabase1ClientProvider);
      final response = await supabase
          .from('leet_solution')
          .select('id')
          .eq('question_id', question['id'])
          .limit(1);
      solutionExists = (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking solution: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF171330) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.indigo.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal header badges & close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            question['difficulty'] ?? 'Easy',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            question['parent_topic'] ?? 'Array',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white54,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Title
                Text(
                  question['question_name'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Priority #${question['priority_order'] ?? 1} — What would you like to do?',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // Action options stacked vertically
                Column(
                  children: [
                    _buildOptionCard(
                      title: 'View Question',
                      description:
                          'Open the problem in the interactive webview solver.',
                      icon: Icons.open_in_new_rounded,
                      iconColor: const Color(0xFF10B981),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeetCodeWebViewScreen(
                              url:
                                  question['question_link'] ??
                                  'https://leetcode.com/',
                              title: question['question_name'] ?? 'LeetCode',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOptionCard(
                      title: solutionExists
                          ? 'View Solution'
                          : 'Generate Solution',
                      description: solutionExists
                          ? 'Check existing step-by-step optimal answers.'
                          : 'Create a new AI-guided solution walkthrough.',
                      icon: solutionExists
                          ? Icons.code_rounded
                          : Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SolutionViewerScreen(
                              questionId: question['id'],
                              questionName: question['question_name'] ?? '',
                              difficulty: question['difficulty'] ?? 'Easy',
                              parentTopic: question['parent_topic'] ?? 'Array',
                              leetcodeUrl:
                                  question['question_link'] ??
                                  'https://leetcode.com/',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1B4B).withOpacity(0.25)
                : Colors.indigo.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.indigo.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : Colors.black38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
