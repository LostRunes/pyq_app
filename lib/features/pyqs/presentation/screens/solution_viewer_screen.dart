import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/core/providers.dart';
import 'package:focus_fox/features/prep_zone/presentation/screens/leetcode_webview_screen.dart';

class SolutionViewerScreen extends ConsumerStatefulWidget {
  final String questionId;
  final String questionName;
  final String difficulty;
  final String parentTopic;
  final String leetcodeUrl;

  const SolutionViewerScreen({
    super.key,
    required this.questionId,
    required this.questionName,
    required this.difficulty,
    required this.parentTopic,
    required this.leetcodeUrl,
  });

  @override
  ConsumerState<SolutionViewerScreen> createState() => _SolutionViewerScreenState();
}

class _SolutionViewerScreenState extends ConsumerState<SolutionViewerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _solutions = [];
  
  // Selected state
  String? _selectedLanguage;
  int _selectedSolutionIndex = 0;
  
  // Custom theme colors for editor
  final List<Color> _themeColors = [
    const Color(0xFF1E1E2E), // Obsidian / Catppuccin Mocha
    const Color(0xFF0F172A), // Slate Dark
    const Color(0xFF18181B), // Zinc Black
    const Color(0xFF050505), // Pure Amoled Black
    const Color(0xFF1B2A4A), // Midnight Blue
  ];
  int _selectedThemeIndex = 0;

  // AI Solution Simulation states
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  bool _showComments = true;

  @override
  void initState() {
    super.initState();
    _fetchSolutions();
  }

  Future<void> _fetchSolutions() async {
    try {
      final supabase = ref.read(supabase1ClientProvider);
      final response = await supabase
          .from('leet_solution')
          .select('*')
          .eq('question_id', widget.questionId)
          .order('priority_order', ascending: true);

      if (mounted) {
        setState(() {
          _solutions = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
          
          if (_solutions.isNotEmpty) {
            // Find all unique languages
            final langs = _solutions.map((s) => s['language'] as String).toSet().toList();
            if (langs.isNotEmpty) {
              _selectedLanguage = langs.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching solutions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Generate Simulated AI Solution
  Future<void> _generateAISolution() async {
    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
    });

    // Simulate progress ticks
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() {
        _generationProgress = i / 10.0;
      });
    }

    // High quality mock solutions
    final mockSolutions = [
      {
        'language': 'C++',
        'heading': 'Optimal Two-Pointer / Hash Solution (AI)',
        'time_complexity': 'O(N)',
        'space_complexity': 'O(N)',
        'solution': '// AI Generated Solution\n#include <vector>\n#include <unordered_map>\n\nclass Solution {\npublic:\n    std::vector<int> solveOptimal(std::vector<int>& nums, int target) {\n        std::unordered_map<int, int> numMap;\n        for (int i = 0; i < nums.size(); i++) {\n            int complement = target - nums[i];\n            if (numMap.find(complement) != numMap.end()) {\n                return {numMap[complement], i};\n            }\n            numMap[nums[i]] = i;\n        }\n        return {};\n    }\n};',
      },
      {
        'language': 'Java',
        'heading': 'Optimal Two-Pointer / Hash Solution (AI)',
        'time_complexity': 'O(N)',
        'space_complexity': 'O(N)',
        'solution': '// AI Generated Solution\nimport java.util.HashMap;\nimport java.util.Map;\n\nclass Solution {\n    public int[] solveOptimal(int[] nums, int target) {\n        Map<Integer, Integer> map = new HashMap<>();\n        for (int i = 0; i < nums.length; i++) {\n            int complement = target - nums[i];\n            if (map.containsKey(complement)) {\n                return new int[] { map.get(complement), i };\n            }\n            map.put(nums[i], i);\n        }\n        return new int[] {};\n    }\n}',
      },
      {
        'language': 'Python',
        'heading': 'Optimal Two-Pointer / Hash Solution (AI)',
        'time_complexity': 'O(N)',
        'space_complexity': 'O(N)',
        'solution': '# AI Generated Solution\nclass Solution:\n    def solveOptimal(self, nums: List[int], target: int) -> List[int]:\n        num_map = {}\n        for i, num in enumerate(nums):\n            complement = target - num\n            if complement in num_map:\n                return [num_map[complement], i]\n            num_map[num] = i\n        return []',
      }
    ];

    if (mounted) {
      setState(() {
        _solutions = mockSolutions;
        _selectedLanguage = 'C++';
        _selectedSolutionIndex = 0;
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final difficultyColor = widget.difficulty.toLowerCase() == 'easy'
        ? const Color(0xFF10B981)
        : widget.difficulty.toLowerCase() == 'medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0C20) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF171330) : theme.appBarTheme.backgroundColor,
        title: Text(
          widget.questionName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeetCodeWebViewScreen(
                    url: widget.leetcodeUrl,
                    title: widget.questionName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new),
            tooltip: 'View Question',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solutions.isEmpty
              ? _buildGenerateAISolutionPrompt(isDark)
              : _buildSolutionsContent(isDark, difficultyColor),
    );
  }

  Widget _buildGenerateAISolutionPrompt(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B4B).withOpacity(0.3) : Colors.indigo.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              size: 80,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Solution in Database',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'There is no pre-saved solution for this question yet.\nGenerate a verified step-by-step AI walkthrough.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          if (_isGenerating) ...[
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _generationProgress,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating optimal algorithms...',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ] else
            ElevatedButton.icon(
              onPressed: _generateAISolution,
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: Text(
                'Generate Solution',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSolutionsContent(bool isDark, Color difficultyColor) {
    // Get unique languages
    final uniqueLanguages = _solutions.map((s) => s['language'] as String).toSet().toList();
    
    // Filter solutions of selected language
    final langSolutions = _solutions
        .where((s) => s['language'] == _selectedLanguage)
        .toList();

    if (_selectedSolutionIndex >= langSolutions.length) {
      _selectedSolutionIndex = 0;
    }

    final activeSolution = langSolutions.isNotEmpty
        ? langSolutions[_selectedSolutionIndex]
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Header metadata
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: difficultyColor.withOpacity(0.3)),
                ),
                child: Text(
                  widget.difficulty,
                  style: GoogleFonts.outfit(
                    color: difficultyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Text(
                  widget.parentTopic,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF818CF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal Language Tabs
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: uniqueLanguages.map((lang) {
                      final isSelected = lang == _selectedLanguage;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            lang,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedLanguage = lang;
                                _selectedSolutionIndex = 0;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: isDark ? const Color(0xFF1E1B4B).withOpacity(0.3) : Colors.grey[200],
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Custom Theme Dots
              Row(
                children: List.generate(_themeColors.length, (index) {
                  final isSelected = index == _selectedThemeIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedThemeIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _themeColors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (activeSolution != null) ...[
            // Solution title / Heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    activeSolution['heading'] ?? 'Solution',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                
                // Show comments switcher
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showComments = !_showComments;
                    });
                  },
                  icon: Icon(
                    _showComments ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: const Color(0xFF38BDF8),
                  ),
                  label: Text(
                    _showComments ? 'Hide Comments' : 'Show Comments',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Complexity and Switchers row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (activeSolution['time_complexity'] != null)
                      _buildComplexityBadge(
                        'Time: ${activeSolution['time_complexity']}',
                        const Color(0xFF10B981),
                      ),
                    const SizedBox(width: 8),
                    if (activeSolution['space_complexity'] != null)
                      _buildComplexityBadge(
                        'Space: ${activeSolution['space_complexity']}',
                        const Color(0xFF3B82F6),
                      ),
                  ],
                ),
                
                // Alternate solutions switcher
                if (langSolutions.length > 1)
                  Row(
                    children: List.generate(langSolutions.length, (idx) {
                      final isSel = idx == _selectedSolutionIndex;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSolutionIndex = idx;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Sol ${idx + 1}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Code editor / viewer card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _themeColors[_selectedThemeIndex],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: SelectableText.rich(
                _buildHighlightedCode(
                  _processCode(activeSolution['solution'] ?? ''),
                  isDark,
                ),
                style: GoogleFonts.sourceCodePro(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _processCode(String rawCode) {
    if (_showComments) {
      return rawCode;
    }
    // Simple regex/filter to strip single line comments
    return rawCode
        .split('\n')
        .where((line) => !line.trim().startsWith('//') && !line.trim().startsWith('#'))
        .join('\n');
  }

  TextSpan _buildHighlightedCode(String code, bool isDark) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(
      r'(//[^\n]*|/\*[\s\S]*?\*/)' // 1: Comments
      r'|("[^"\\]*(?:\\.[^"\\]*)*")' // 2: Double-quoted Strings
      r"|('[^'\\]*(?:\\.[^'\\]*)*')" // 3: Single-quoted Chars
      r'|(\b(?:int|double|float|char|void|long|boolean|bool|short|byte|class|interface|public|private|protected|static|final|const|volatile|transient|synchronized|native|if|else|for|while|do|switch|case|default|break|continue|return|try|catch|finally|throw|throws|new|this|super|import|package|struct|typedef|template|typename|using|namespace|virtual|override|nullptr|true|false)\b)' // 4: Keywords
      r'|(\b\d+(?:\.\d+)?\b)' // 5: Numbers
      r'|(#[a-zA-Z_]+|@[a-zA-Z_]+)' // 6: Preprocessor/Annotations
    );

    int lastIndex = 0;
    final defaultTextColor = const Color(0xFFF8F8F2);

    for (final match in regex.allMatches(code)) {
      // Add text before the match (whitespaces, operators, punctuation, etc.)
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: GoogleFonts.sourceCodePro(color: defaultTextColor),
        ));
      }

      final matchedText = match.group(0)!;
      Color color = defaultTextColor;
      FontWeight fontWeight = FontWeight.normal;

      if (match.group(1) != null) {
        // Comment
        color = const Color(0xFF6272A4); // Dracula comment color (greyish blue)
      } else if (match.group(2) != null || match.group(3) != null) {
        // String or Char
        color = const Color(0xFFF1FA8C); // Dracula yellow string
      } else if (match.group(4) != null) {
        // Keyword
        color = const Color(0xFFFF79C6); // Dracula pink keyword
        fontWeight = FontWeight.bold;
      } else if (match.group(5) != null) {
        // Number
        color = const Color(0xFFBD93F9); // Dracula purple number
      } else if (match.group(6) != null) {
        // Preprocessor or Annotation
        color = const Color(0xFFFFB86C); // Dracula orange annotation
      }

      spans.add(TextSpan(
        text: matchedText,
        style: GoogleFonts.sourceCodePro(color: color, fontWeight: fontWeight),
      ));
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: GoogleFonts.sourceCodePro(color: defaultTextColor),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildComplexityBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
