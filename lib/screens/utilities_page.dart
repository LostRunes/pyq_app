import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';
import '../utils/fuzzy_search.dart';

class UtilitiesPage extends ConsumerWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(utilitiesSearchProvider);

    final utils = [
      {
        'title': 'GPA Calculator',
        'desc': 'Track grades & semester GPA',
        'icon': Icons.calculate_rounded,
        'route': '/gpa_calc',
        'color': const Color(0xFF10B981), // Emerald
      },
      {
        'title': 'Study Together',
        'desc': 'Join peer study rooms & voice lounges',
        'icon': Icons.group_work_rounded,
        'route': '/study_together',
        'color': const Color(0xFF6366F1), // Indigo
      },
      {
        'title': 'Syllabus',
        'desc': 'Explore subjects & credits',
        'icon': Icons.collections_bookmark_rounded,
        'route': '/syllabus',
        'color': const Color(0xFFF59E0B), // Amber
      },
    ];

    final filteredUtils = utils.where((util) {
      return FuzzySearch.matches(util['title'] as String?, searchQuery) ||
          FuzzySearch.matches(util['desc'] as String?, searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Utilities',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Access all essential tools and peer rooms',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          filteredUtils.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  alignment: Alignment.center,
                  child: Text(
                    'No matching utilities found 🔍',
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
                  itemCount: filteredUtils.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0, // Force square boxes
                  ),
                  itemBuilder: (context, index) {
                    final util = filteredUtils[index];
                    final Color utilColor = util['color'] as Color;
              return InkWell(
                onTap: () {
                  Navigator.pushNamed(context, util['route'] as String);
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: utilColor.withOpacity(0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: utilColor.withOpacity(0.06),
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
                          color: utilColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          util['icon'] as IconData,
                          color: utilColor,
                          size: 26,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            util['title'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            util['desc'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
