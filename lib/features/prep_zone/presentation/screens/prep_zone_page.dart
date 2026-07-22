import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/features/prep_zone/presentation/providers/prep_zone_providers.dart';
import 'package:focus_fox/utils/fuzzy_search.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import 'package:lottie/lottie.dart';

class PrepZonePage extends ConsumerWidget {
  const PrepZonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(prepZoneSearchProvider);
    final isDark = theme.brightness == Brightness.dark;

    final Color orangeBgStart = isDark
        ? const Color(0xFF251E4E)
        : const Color.fromARGB(255, 251, 203, 158);
    final Color orangeBgEnd = isDark
        ? const Color(0xFF15112E)
        : const Color.fromARGB(255, 238, 206, 154);

    final prepItems = [
      {
        'title': 'Algo+Code',
        'desc': 'DSA patterns & Coding roadmaps',
        'icon': Icons.code_rounded,
        'route': '/algo_code',
        'color': orangeBgStart,
        'isComingSoon': false,
        'lottie': 'json/coding.json',
      },
      {
        'title': 'KIIT Syllabus',
        'desc': 'Explore subjects & credits',
        'icon': Icons.collections_bookmark_rounded,
        'route': '/syllabus',
        'color': const Color(0xFFF59E0B), // Amber
        'isComingSoon': false,
        'lottie': 'json/robot_syllabus.json',
      },
      {
        'title': 'Aptitude',
        'desc': 'Quantitative, logical reasoning & verbal ability',
        'icon': Icons.psychology_rounded,
        'route': '/aptitude_topics',
        'color': const Color(0xFF8B5CF6), // Purple
        'isComingSoon': false,
        'lottie': 'json/aptitude.json',
      },
      {
        'title': 'GATE',
        'desc': 'Graduate Aptitude Test in Engineering prep',
        'icon': Icons.school_rounded,
        'route': '/gate_prep',
        'color': const Color(0xFF10B981), // Emerald
        'isComingSoon': false,
        'lottie': 'json/gate_fox.json',
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
          FadeInSlide(
            duration: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
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
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final Color itemColor = item['color'] as Color;

                    return FadeInSlide(
                      delay: Duration(milliseconds: index * 100),
                      duration: const Duration(milliseconds: 500),
                      child: InkWell(
                        onTap: (item['isComingSoon'] as bool? ?? false)
                            ? () {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${item['title']} is coming soon!',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  item['route'] as String,
                                );
                              },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: itemColor.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: itemColor.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 85,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [orangeBgStart, orangeBgEnd],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(22),
                                    topRight: Radius.circular(22),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['desc'] as String,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.75)
                                            : Colors.black.withOpacity(0.7),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Center(
                                        child: Lottie.asset(
                                          item['lottie'] as String,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    if (item['isComingSoon'] as bool? ?? false)
                                      Positioned(
                                        bottom: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'Coming soon..',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 40),
          FadeInSlide(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 500),
            child: Center(
              child: Text(
                'More features coming soon...',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
