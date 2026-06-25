import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/features/utilities/presentation/providers/utilities_providers.dart';
import 'package:focus_fox/utils/fuzzy_search.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';

class UtilitiesPage extends ConsumerWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(utilitiesSearchProvider);
    final isDark = theme.brightness == Brightness.dark;

    final utils = [
      {
        'title': 'Scientific Calculator',
        'desc': 'Casio-style advanced math tool',
        'icon': Icons.calculate_rounded,
        'route': '/scientific_calculator',
        'color': const Color(0xFF8B5CF6), // Purple
      },
      {
        'title': 'GPA Calculator',
        'desc': 'Track grades & semester GPA',
        'icon': Icons.calculate_rounded,
        'route': '/gpa_calculator',
        'color': const Color(0xFF10B981), // Emerald
      },
      {
        'title': 'Upload Notes',
        'desc': 'Share study notes & materials',
        'icon': Icons.cloud_upload_rounded,
        'route': '/upload_notes',
        'color': const Color(0xFF6366F1), // Indigo
      },
      {
        'title': 'Syllabus',
        'desc': 'Explore subjects & credits',
        'icon': Icons.collections_bookmark_rounded,
        'route': '/syllabus',
        'color': const Color(0xFFF59E0B), // Amber
      },
      {
        'title': 'Focus Timer',
        'desc': 'Set a timer to stay focused',
        'icon': Icons.timer_rounded,
        'route': '/focus_timer',
        'color': const Color(0xFFEC4899), // Pink
      },
      {
        'title': 'To Do Dashboard',
        'desc': 'Track study activity & custom tasks',
        'icon': Icons.playlist_add_check_rounded,
        'route': '/todo_dashboard',
        'color': const Color(0xFF6366F1), // Indigo
      }
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
          FadeInSlide(
            duration: const Duration(milliseconds: 500),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Utilities',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Access essential tools & plan your day',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
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
                    childAspectRatio: 0.95, // Prevent overflow on smaller screens
                  ),
                  itemBuilder: (context, index) {
                    final util = filteredUtils[index];
                    final Color utilColor = util['color'] as Color;
                    return FadeInSlide(
                      delay: Duration(milliseconds: index * 100),
                      duration: const Duration(milliseconds: 500),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, util['route'] as String);
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1B4B).withOpacity(0.2) : theme.colorScheme.surface,
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
                                padding: const EdgeInsets.all(8),
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
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
