import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';
import 'package:focus_fox/utils/fuzzy_search.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import 'package:lottie/lottie.dart';

class SubjectsPage extends ConsumerWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentBranchId = ref.watch(selectedBranchIdProvider);
    final currentSemester = ref.watch(selectedSemesterProvider);

    final subjectsAsync = ref.watch(
      subjectsProvider((branchId: currentBranchId, semester: currentSemester)),
    );

    final searchQuery = ref.watch(subjectsSearchProvider);

    return FlyingBeeOverlay(
      child: RefreshIndicator(
        onRefresh: () async {
          final _ = await ref.refresh(
            subjectsProvider((
              branchId: currentBranchId,
              semester: currentSemester,
            )).future,
          );
        },
        child: subjectsAsync.when(
          data: (subjects) {
            final filtered = subjects.where((subject) {
              return FuzzySearch.matches(subject.name, searchQuery) ||
                  FuzzySearch.matches(subject.code, searchQuery);
            }).toList();

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return FadeInSlide(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Subjects',
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/selection',
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Back',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GhostText(
                                      text: 'Choose your path!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? const Color(0xFFFFFFFF)
                                                : Colors.black,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    GhostText(
                                      text: 'Select a subject to begin.',
                                      delay: const Duration(milliseconds: 350),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              ZoomInFlash(
                                delay: const Duration(milliseconds: 600),
                                duration: const Duration(milliseconds: 750),
                                child: SizedBox(
                                  height: 140,
                                  width: 140,
                                  child: Image.asset('assets/images/panda.png'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No matching subjects found 🔍',
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                final subject = filtered[i - 1];
                final isIconLeft = (i - 1) % 2 == 0;

                final iconWidget = Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.book_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                );

                final textWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Code: ${subject.code}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                        ),
                        if (subject.subjectCredit != null ||
                            subject.subjectType != null) ...[
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (subject.subjectCredit != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${subject.subjectCredit} Cr',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                        if (subject.subjectType != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  subject.subjectType!.toLowerCase() == 'core'
                                  ? Colors.redAccent.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subject.subjectType!.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    subject.subjectType!.toLowerCase() == 'core'
                                    ? Colors.redAccent
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );

                return ExpandingSubjectCard(
                  isIconLeft: isIconLeft,
                  delay: Duration(milliseconds: (i - 1).clamp(0, 6) * 150),
                  duration: const Duration(milliseconds: 900),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/subject_dashboard',
                          arguments: {'subject': subject},
                        );
                      },
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFFF9F0A).withOpacity(0.28)),
                            width: 1.5,
                          ),
                          boxShadow: [
                            // Soft Apple system orange glow from behind
                            if (!isDark)
                              BoxShadow(
                                color: const Color(
                                  0xFFFF9F0A,
                                ).withOpacity(0.12),
                                blurRadius: 24,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  if (isIconLeft) ...[
                                    iconWidget,
                                    const SizedBox(width: 20),
                                  ],
                                  Expanded(child: textWidget),
                                  if (!isIconLeft) ...[
                                    const SizedBox(width: 20),
                                    iconWidget,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error: $e\n\nPull down to retry',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlyingBeeOverlay extends StatefulWidget {
  final Widget child;
  const FlyingBeeOverlay({super.key, required this.child});

  @override
  State<FlyingBeeOverlay> createState() => _FlyingBeeOverlayState();
}

class _FlyingBeeOverlayState extends State<FlyingBeeOverlay>
    with SingleTickerProviderStateMixin {
  double _x = -150;
  double _y = -150;
  double _angle = 0;
  double _opacity = 0;
  late Timer _timer;
  final Random _random = Random();
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 12), (timer) {
      _startFlight();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startFlight();
    });
  }

  void _startFlight() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final startLeft = _random.nextBool();

    final double startX = startLeft ? -100 : size.width + 100;
    final double startY = _random.nextDouble() * (size.height - 200) + 100;

    final double endX = startLeft ? size.width + 100 : -100;
    final double endY = _random.nextDouble() * (size.height - 200) + 100;

    setState(() {
      _x = startX;
      _y = startY;
      _opacity = 0.55; // Cute transparent bee
      _isFlipped = !startLeft;
      _angle = atan2(endY - startY, endX - startX);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _x = endX;
        _y = endY;
      });
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() {
        _opacity = 0.0;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(seconds: 6),
          curve: Curves.easeInOutCubic,
          left: _x,
          top: _y,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _opacity,
            child: Transform.rotate(
              angle: _angle,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(_isFlipped ? -1.0 : 1.0, 1.0),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Lottie.asset(
                    'json/Honey_bee.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Silent failure — show nothing if bee can't load
                      return const SizedBox.shrink();
                    },
                    frameBuilder: (context, child, composition) {
                      if (composition == null) return const SizedBox.shrink();
                      return child;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
