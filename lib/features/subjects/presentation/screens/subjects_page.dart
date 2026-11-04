import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/services/analytics_service.dart';
import 'package:focus_fox/features/auth/presentation/screens/main_navigation_screen.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers/bee_provider.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';
import 'package:focus_fox/utils/fuzzy_search.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import 'package:focus_fox/core/providers.dart';
import 'package:focus_fox/features/pyqs/data/models/subject.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    final customOrder = ref.watch(
      subjectOrderProvider((branchId: currentBranchId, semester: currentSemester)),
    );

    final beeEnabled = ref.watch(beeEnabledProvider);
    final selectedIndex = ref.watch(mainNavigationIndexProvider);
    final hasShownAnimation = ref.watch(hasShownSubjectTitleAnimationProvider);

    if (!hasShownAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(hasShownSubjectTitleAnimationProvider.notifier).setShown(true);
      });
    }

    return FlyingBeeOverlay(
      beeEnabled: beeEnabled,
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
            final filtered =
                subjects.where((subject) {
                  return FuzzySearch.matches(subject.name, searchQuery) ||
                      FuzzySearch.matches(subject.code, searchQuery);
                }).toList();

            if (customOrder.isNotEmpty) {
              filtered.sort((a, b) {
                final indexA = customOrder.indexOf(a.id);
                final indexB = customOrder.indexOf(b.id);
                if (indexA != -1 && indexB != -1) {
                  return indexA.compareTo(indexB);
                } else if (indexA != -1) {
                  return -1;
                } else if (indexB != -1) {
                  return 1;
                } else {
                  final aIsCore = a.subjectType?.toLowerCase() == 'core';
                  final bIsCore = b.subjectType?.toLowerCase() == 'core';
                  if (aIsCore != bIsCore) return aIsCore ? -1 : 1;
                  final aCredits = a.subjectCredit ?? 0;
                  final bCredits = b.subjectCredit ?? 0;
                  return bCredits.compareTo(aCredits);
                }
              });
            } else {
              filtered.sort((a, b) {
                final aIsCore = a.subjectType?.toLowerCase() == 'core';
                final bIsCore = b.subjectType?.toLowerCase() == 'core';
                if (aIsCore != bIsCore) return aIsCore ? -1 : 1;
                final aCredits = a.subjectCredit ?? 0;
                final bCredits = b.subjectCredit ?? 0;
                return bCredits.compareTo(aCredits);
              });
            }

            return ReorderableListView.builder(
              key: ValueKey(selectedIndex),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: filtered.isEmpty ? 3 : filtered.length + 2,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (filtered.isEmpty) return;
                // Header (0) and Footer (filtered.length + 1) cannot be dragged,
                // and nothing can be dragged into their positions.
                if (oldIndex < 1 || oldIndex > filtered.length) return;

                var targetNew = newIndex;
                if (targetNew < 1) targetNew = 1;
                if (targetNew > filtered.length + 1) {
                  targetNew = filtered.length + 1;
                }

                if (oldIndex == targetNew || oldIndex == targetNew - 1) return;

                final int actualOld = oldIndex - 1;
                int actualNew = targetNew - 1;
                if (actualNew > actualOld) {
                  actualNew -= 1;
                }

                final item = filtered.removeAt(actualOld);
                filtered.insert(actualNew, item);

                final orderedIds = filtered.map((s) => s.id).toList();
                ref
                    .read(
                      subjectOrderProvider((
                        branchId: currentBranchId,
                        semester: currentSemester,
                      )).notifier,
                    )
                    .updateOrder(orderedIds);
              },
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Container(
                    key: const ValueKey('header'),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInSlide(
                          duration: const Duration(milliseconds: 500),
                          child: Row(
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
                                onTap: () => Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/selection',
                                  (route) => false,
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
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: FadeInSlide(
                                duration: const Duration(milliseconds: 500),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasShownAnimation)
                                      Text(
                                        'Choose your path!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: isDark
                                                  ? const Color(0xFFFFFFFF)
                                                  : Colors.black,
                                            ),
                                      )
                                    else
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
                                    if (hasShownAnimation)
                                      Text(
                                        'Select a subject to begin.',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      )
                                    else
                                      GhostText(
                                        text: 'Select a subject to begin.',
                                        delay: const Duration(
                                          milliseconds: 350,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 140,
                              width: 140,
                              child: Image.asset('assets/images/panda.png'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                if (filtered.isEmpty && i == 1) {
                  return Center(
                    key: const ValueKey('empty_state'),
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

                if (i == (filtered.isEmpty ? 2 : filtered.length + 1)) {
                  return Container(
                    key: const ValueKey('add_subject_card'),
                    child: _buildAddSubjectCard(
                      context,
                      ref,
                      currentBranchId,
                      currentSemester,
                    ),
                  );
                }

                final subject = filtered[i - 1];
                final isIconLeft = (i - 1) % 2 == 0;
                final iconColor = Theme.of(context).colorScheme.primary;

                final iconWidget = ReorderableDragStartListener(
                  index: i,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        isDark
                            ? 'assets/images/honey_dark.png'
                            : 'assets/images/honey_light.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );

                final textWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
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
                        if (subject.subjectCredit != null) ...[
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${subject.subjectCredit} Credits',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );

                Widget cardWidget = InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/subject_dashboard',
                      arguments: {'subject': subject},
                    );
                  },
                  onLongPress: () {
                    _showDeleteConfirmationDialog(
                      context,
                      ref,
                      currentBranchId,
                      currentSemester,
                      subject,
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
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFFF9F0A).withOpacity(0.28)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: const Color(0xFFFF9F0A).withOpacity(0.12),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
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
                );

                Widget cardAnimWidget = ExpandingSubjectCard(
                  isIconLeft: isIconLeft,
                  delay: Duration(milliseconds: (i - 1).clamp(0, 6) * 150),
                  duration: const Duration(milliseconds: 900),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: cardWidget,
                  ),
                );

                if (filtered.isNotEmpty && i == filtered.length) {
                  cardAnimWidget = Stack(
                    clipBehavior: Clip.none,
                    children: [
                      cardAnimWidget,
                      Positioned(
                        top:
                            -28, // Sits perfectly on top of the card's top edge
                        left: isIconLeft
                            ? -25
                            : -20, // Positioned on top of the card/icon
                        child: Image.asset(
                          'assets/images/eat_fox.png',
                          width: 85,
                          height: 85,
                        ),
                      ),
                    ],
                  );
                }

                return SubjectCardFade(
                  key: ValueKey(subject.id),
                  delay: Duration(milliseconds: (i - 1).clamp(0, 5) * 60),
                  child: cardAnimWidget,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 180,
                          width: 180,
                          child: Image.asset(
                            'assets/images/frustrated_racoon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Oops, no internet!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load subjects. Please check your connection and pull down to retry.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Details: $e',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                      ],
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

class FlyingBeeOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final bool beeEnabled;
  const FlyingBeeOverlay({
    super.key,
    required this.child,
    required this.beeEnabled,
  });

  @override
  ConsumerState<FlyingBeeOverlay> createState() => _FlyingBeeOverlayState();
}

class _FlyingBeeOverlayState extends ConsumerState<FlyingBeeOverlay>
    with TickerProviderStateMixin {
  static const double _beeSize = 80.0;

  // Current position (clamped to screen)
  double _x = -200;

  // Drop-down state
  double _dropY = -200;
  bool _dropped = false;
  bool _visible = false;
  bool _dropping = false;

  // Wander
  Timer? _wanderTimer;
  Timer? _initialSpawnTimer; // cancellable replacement for Future.delayed
  Timer? _reappearTimer; // cancellable replacement for Future.delayed
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Start first appearance after 2 seconds (only if bee is enabled)
    _initialSpawnTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && widget.beeEnabled) _spawnBee();
    });
  }

  @override
  void didUpdateWidget(FlyingBeeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.beeEnabled && _visible) {
      // Bee was disabled — hide immediately
      _wanderTimer?.cancel();
      setState(() {
        _visible = false;
        _dropped = true;
        _dropping = false;
        _x = -200;
        _dropY = -200;
      });
    } else if (widget.beeEnabled && !oldWidget.beeEnabled) {
      // Bee was re-enabled — spawn fresh
      _dropped = false;
      _reappearTimer?.cancel();
      _reappearTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) _spawnBee();
      });
    }
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
      _dropY = pos.dy;
    });
  }

  void _onTap() {
    if (!_visible || _dropped || _dropping) return;
    _wanderTimer?.cancel();

    // Trigger haptic feedback
    HapticFeedback.lightImpact();

    // Capture the start position of the bubble animation
    final startOffset = Offset(_x + _beeSize / 2, _dropY + _beeSize / 2);
    _showFloatingPlusOne(startOffset);

    // Log the bee tap event
    AnalyticsService.logFeatureUsed(
      featureName: 'bee_killed',
      screenName: '/main_navigation',
      metadata: {
        'new_count': ref.read(beeTapCountProvider) + 1,
      },
    );

    // Increment the quest counter
    ref.read(beeTapCountProvider.notifier).increment();

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
        _dropY = -200;
      });
    });

    // Reappear after 10 seconds (if still enabled)
    _reappearTimer?.cancel();
    _reappearTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && widget.beeEnabled) _spawnBee();
    });
  }

  void _showFloatingPlusOne(Offset startOffset) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final RenderBox? profileBox =
        MainNavigationScreen.profileIconKey.currentContext?.findRenderObject()
            as RenderBox?;
    final Offset targetOffset;
    if (profileBox != null) {
      targetOffset = profileBox.localToGlobal(
        profileBox.size.center(Offset.zero),
      );
    } else {
      final size = MediaQuery.of(context).size;
      targetOffset = Offset(
        size.width - 45,
        MediaQuery.of(context).padding.top + 28,
      );
    }

    entry = OverlayEntry(
      builder: (context) => _FloatingPlusOneBubble(
        startOffset: startOffset,
        targetOffset: targetOffset,
        onComplete: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  void dispose() {
    _wanderTimer?.cancel();
    _initialSpawnTimer?.cancel();
    _reappearTimer?.cancel();
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
            child: RepaintBoundary(
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
                        if (composition == null) {
                          return const SizedBox.shrink();
                        }
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

class _FloatingPlusOneBubble extends StatefulWidget {
  final Offset startOffset;
  final Offset targetOffset;
  final VoidCallback onComplete;

  const _FloatingPlusOneBubble({
    required this.startOffset,
    required this.targetOffset,
    required this.onComplete,
  });

  @override
  State<_FloatingPlusOneBubble> createState() => _FloatingPlusOneBubbleState();
}

class _FloatingPlusOneBubbleState extends State<_FloatingPlusOneBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        final currentX =
            widget.startOffset.dx +
            (widget.targetOffset.dx - widget.startOffset.dx) * t;
        final currentY =
            widget.startOffset.dy +
            (widget.targetOffset.dy - widget.startOffset.dy) * t;

        final opacity = (1.0 - t).clamp(0.0, 1.0);
        final scale = t < 0.2 ? (t / 0.2) * 1.2 : 1.2 - ((t - 0.2) / 0.8) * 0.4;

        return Positioned(
          left: currentX - 25,
          top: currentY - 15,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9F0A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9F0A).withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+1',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 2),
              const Text('🐝', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers and Dialogs for Adding/Deleting Subjects
// ---------------------------------------------------------------------------

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dash = 6.0,
    this.borderRadius = 32.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showDeleteConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
  String branchId,
  int semester,
  Subject subject,
) {
  showDialog(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF171330) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Subject?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${subject.name}" from this subject list?',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(subjectsRepositoryProvider)
                    .deleteSubjectFromSemester(
                      branchId: branchId,
                      semester: semester,
                      subjectId: subject.id,
                    );
                ref.invalidate(subjectsProvider((
                  branchId: branchId,
                  semester: semester,
                )));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully removed ${subject.name}'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete subject: $e')),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildAddSubjectCard(
  BuildContext context,
  WidgetRef ref,
  String currentBranchId,
  int currentSemester,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final Color orangeColor = const Color(0xFFFF9F0A);
  final Color fillBg = orangeColor.withOpacity(isDark ? 0.05 : 0.08);

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () {
        _showAddSubjectDialog(context, ref, currentBranchId, currentSemester);
      },
      borderRadius: BorderRadius.circular(32),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: orangeColor.withOpacity(0.5),
          borderRadius: 32,
        ),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: fillBg,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 32, color: orangeColor),
                const SizedBox(height: 8),
                Text(
                  'Add Subjects',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: orangeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showAddSubjectDialog(
  BuildContext context,
  WidgetRef ref,
  String currentBranchId,
  int currentSemester,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Subject',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: _AddSubjectDialogContent(
            initialBranchId: currentBranchId,
            initialSemester: currentSemester,
          ),
        ),
      );
    },
  );
}

class _AddSubjectDialogContent extends ConsumerStatefulWidget {
  final String initialBranchId;
  final int initialSemester;

  const _AddSubjectDialogContent({
    required this.initialBranchId,
    required this.initialSemester,
  });

  @override
  ConsumerState<_AddSubjectDialogContent> createState() =>
      _AddSubjectDialogContentState();
}

class _AddSubjectDialogContentState
    extends ConsumerState<_AddSubjectDialogContent> {
  late String _selectedBranchId;
  late int _selectedSemester;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.initialBranchId;
    _selectedSemester = widget.initialSemester;
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);

    // We watch the global default subjects for the selected branch/semester in the popup (source)
    final sourceSubjectsAsync = ref.watch(
      globalSubjectsProvider((
        branchId: _selectedBranchId,
        semester: _selectedSemester,
      )),
    );

    // We watch the subjects for the current screen (target)
    final currentSubjectsAsync = ref.watch(
      subjectsProvider((
        branchId: widget.initialBranchId,
        semester: widget.initialSemester,
      )),
    );

    if (branchesAsync.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final branches = branchesAsync.value ?? [];
    final sourceSubjects = sourceSubjectsAsync.value ?? [];
    final currentSubjects = currentSubjectsAsync.value ?? [];

    final isSourceLoading = sourceSubjectsAsync.isLoading;
    final isCurrentLoading = currentSubjectsAsync.isLoading;

    final currentIds = currentSubjects.map((s) => s.id).toSet();
    final availableSubjects = sourceSubjects
        .where((s) => !currentIds.contains(s.id))
        .toList();

    // Reset selection if the current selected subject has been filtered out
    if (_selectedSubjectId != null &&
        !availableSubjects.any((s) => s.id == _selectedSubjectId)) {
      _selectedSubjectId = null;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedBranchId,
          decoration: InputDecoration(
            labelText: 'Branch',
            labelStyle: GoogleFonts.outfit(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: branches.map((b) {
            return DropdownMenuItem(
              value: b.id,
              child: Text(
                b.name,
                style: GoogleFonts.outfit(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedBranchId = val;
                _selectedSubjectId = null;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: _selectedSemester,
          decoration: InputDecoration(
            labelText: 'Semester',
            labelStyle: GoogleFonts.outfit(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: List.generate(8, (index) => index + 1).map((sem) {
            return DropdownMenuItem(
              value: sem,
              child: Text(
                'Semester $sem',
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedSemester = val;
                _selectedSubjectId = null;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedSubjectId,
          decoration: InputDecoration(
            labelText: 'Subject',
            labelStyle: GoogleFonts.outfit(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: isSourceLoading || isCurrentLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          hint: Text(
            isSourceLoading || isCurrentLoading
                ? 'Loading subjects...'
                : 'Select Subject',
            style: GoogleFonts.outfit(fontSize: 14),
          ),
          items: availableSubjects.map((s) {
            return DropdownMenuItem(
              value: s.id,
              child: Text(
                '${s.name} (${s.code})',
                style: GoogleFonts.outfit(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: isSourceLoading || isCurrentLoading
              ? null
              : (val) {
                  setState(() {
                    _selectedSubjectId = val;
                  });
                },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9F0A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed:
              _selectedSubjectId == null || isSourceLoading || isCurrentLoading
              ? null
              : () async {
                  try {
                    // Add chosen subject to target/current screen branch & sem
                    await ref
                        .read(subjectsRepositoryProvider)
                        .addSubjectToSemester(
                          branchId: widget.initialBranchId,
                          semester: widget.initialSemester,
                          subjectId: _selectedSubjectId!,
                        );

                    // Force invalidate target page subjects Provider so it pulls the non-cached fresh list
                    ref.invalidate(subjectsProvider((
                      branchId: widget.initialBranchId,
                      semester: widget.initialSemester,
                    )));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully added subject'),
                        ),
                      );
                    }
                  } on PostgrestException catch (e) {
                    if (context.mounted) {
                      final message = e.code == '23505'
                          ? 'This subject is already added to this branch and semester.'
                          : 'Failed to add subject: ${e.message}';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add subject: $e')),
                      );
                    }
                  }
                },
          child: Text(
            'Add Subject',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
