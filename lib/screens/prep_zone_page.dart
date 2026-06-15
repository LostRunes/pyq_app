import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';

import '../utils/fuzzy_search.dart';

class PrepZonePage extends ConsumerWidget {
  const PrepZonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(prepZoneSearchProvider);

    final prepItems = [
      {
        'title': 'Algo+Code',
        'desc': 'DSA patterns & Coding roadmaps',
        'icon': Icons.code_rounded,
        'route': '/algo_code',
        'color': const Color(0xFF6366F1), // Indigo
        'isComingSoon': false,
      },
      /*
      {
        'title': 'Gate Prep',
        'desc': 'Previous year GATE papers & syllabus',
        'icon': Icons.menu_book_rounded,
        'route': '/gate_prep',
        'color': const Color(0xFFE11D48), // Rose
        'isComingSoon': false,
      },
      */
      {
        'title': 'Coming Soon',
        'desc': 'More prep tools under development',
        'icon': Icons.hourglass_empty_rounded,
        'route': '',
        'color': Colors.grey,
        'isComingSoon': true,
      },
    ];

    final filteredItems = prepItems.where((item) {
      return FuzzySearch.matches(item['title'] as String?, searchQuery) ||
          FuzzySearch.matches(item['desc'] as String?, searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Prep Zone',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sharpen your coding skills and prepare for core engineering exams.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          filteredItems.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  alignment: Alignment.center,
                  child: Text(
                    'No matching prep tools found 🔍',
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final Color itemColor = item['color'] as Color;
                    final bool isComingSoon = item['isComingSoon'] as bool? ?? false;
              return InkWell(
                onTap: isComingSoon
                    ? null
                    : () {
                        Navigator.pushNamed(context, item['route'] as String);
                      },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: itemColor.withOpacity(0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: itemColor.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: itemColor,
                          size: 26,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
