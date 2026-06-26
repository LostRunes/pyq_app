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
    with TickerProviderStateMixin {
  static const double _beeSize = 80.0;

  // Current position (clamped to screen)
  double _x = -200;
  double _y = -200;

  // Drop-down state
  double _dropY = -200;
  bool _dropped = false;
  bool _visible = false;
  bool _dropping = false;

  // Wander
  Timer? _wanderTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Start first appearance after 2 seconds
    Future.delayed(const Duration(seconds: 2), _spawnBee);
  }

  Size get _screenSize => MediaQuery.of(context).size;

  // Random position safely within screen bounds
  Offset _randomPosition() {
    final s = _screenSize;
    final double x = _random.nextDouble() * (s.width - _beeSize - 32) + 16;
    final double y = _random.nextDouble() * (s.height - _beeSize - 120) + 80;
    return Offset(x, y);
  }

  void _spawnBee() {
    if (!mounted) return;
    final pos = _randomPosition();
    setState(() {
      _x = pos.dx;
      _y = pos.dy;
      _dropY = pos.dy;
      _visible = true;
      _dropped = false;
      _dropping = false;
    });
    // Start wandering
    _scheduleWander();
  }

  void _scheduleWander() {
    _wanderTimer?.cancel();
    _wanderTimer = Timer.periodic(
      Duration(milliseconds: 2500 + _random.nextInt(2000)),
      (_) => _wander(),
    );
  }

  void _wander() {
    if (!mounted || _dropped || _dropping) return;
    final pos = _randomPosition();
    setState(() {
      _x = pos.dx;
      _y = pos.dy;
      _dropY = pos.dy;
    });
  }

  void _onTap() {
    if (!_visible || _dropped || _dropping) return;
    _wanderTimer?.cancel();
    setState(() {
      _dropping = true;
      _dropY = _screenSize.height + 100; // drop off screen
    });

    // After drop animation completes, mark hidden
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _dropped = true;
        _visible = false;
        _dropping = false;
        _x = -200;
        _y = -200;
        _dropY = -200;
      });
    });

    // Reappear after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      _spawnBee();
    });
  }

  @override
  void dispose() {
    _wanderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          AnimatedPositioned(
            duration: _dropping
                ? const Duration(milliseconds: 550)
                : const Duration(milliseconds: 2200),
            curve: _dropping ? Curves.easeIn : Curves.easeInOutSine,
            left: _x,
            top: _dropY,
            child: GestureDetector(
              onTap: _onTap,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _visible ? 0.88 : 0.0,
                child: SizedBox(
                  width: _beeSize,
                  height: _beeSize,
                  child: Lottie.asset(
                    'json/Honey_bee.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
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
      ],
    );
  }
}
