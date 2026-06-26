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
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final Color itemColor = item['color'] as Color;

                    return FadeInSlide(
                      delay: Duration(milliseconds: index * 100),
                      duration: const Duration(milliseconds: 500),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, item['route'] as String);
                        },
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(32),
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
                              Padding(
                                padding: const EdgeInsets.all(28.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: Lottie.asset(
                                      'json/coding.json',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [orangeBgStart, orangeBgEnd],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(30),
                                    bottomRight: Radius.circular(30),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['desc'] as String,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.75)
                                            : Colors.black.withOpacity(0.7),
                                        height: 1.4,
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
