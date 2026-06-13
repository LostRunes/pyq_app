import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlgoCodeScreen extends StatelessWidget {
  const AlgoCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = [
      {
        'title': 'Data Structures',
        'desc': 'Arrays, Trees, Graphs, Heaps',
        'icon': Icons.account_tree_rounded,
        'color': const Color(0xFF6366F1),
        'topics': ['Arrays & Hashing', 'Linked Lists', 'Trees & BSTs', 'Graphs & Traversals'],
      },
      {
        'title': 'Algorithms',
        'desc': 'Sorting, Binary Search, DP',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF10B981),
        'topics': ['Sorting & Searching', 'Recursion & Backtracking', 'Dynamic Programming', 'Greedy Algorithms'],
      },
      {
        'title': 'Practice Platforms',
        'desc': 'LeetCode, Codeforces, GFG',
        'icon': Icons.code_rounded,
        'color': const Color(0xFFF59E0B),
        'topics': ['LeetCode Top 150', 'Striver\'s SDE Sheet', 'GeeksforGeeks Practice', 'Codeforces Rounds'],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Algo + Code Zone',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Master DSA & Coding',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Curated roadmap, cheat sheets, and coding exercises.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final color = cat['color'] as Color;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                cat['icon'] as IconData,
                                color: color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat['title'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    cat['desc'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (cat['topics'] as List<String>).map((t) {
                            return ActionChip(
                              label: Text(
                                t,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                              backgroundColor: color.withOpacity(0.05),
                              side: BorderSide(
                                color: color.withOpacity(0.2),
                                width: 1,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening resources for $t 🚀'),
                                  ),
                                );
                              },
                            );
                          }).toList(),
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
    );
  }
}
