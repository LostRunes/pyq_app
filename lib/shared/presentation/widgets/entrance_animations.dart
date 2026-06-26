import 'package:flutter/material.dart';

enum SlideDirection { up, down, left, right }

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final SlideDirection direction;
  final double slideOffset;
  final Curve curve;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.direction = SlideDirection.up,
    this.slideOffset = 40.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Offset startOffset;
    switch (widget.direction) {
      case SlideDirection.up:
        startOffset = Offset(0.0, widget.slideOffset);
        break;
      case SlideDirection.down:
        startOffset = Offset(0.0, -widget.slideOffset);
        break;
      case SlideDirection.left:
        startOffset = Offset(widget.slideOffset, 0.0);
        break;
      case SlideDirection.right:
        startOffset = Offset(-widget.slideOffset, 0.0);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class GhostText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;

  const GhostText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
  });

  @override
  State<GhostText> createState() => _GhostTextState();
}

class _GhostTextState extends State<GhostText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.text.split(' ');
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: List.generate(words.length, (index) {
            final step = 1.0 / words.length;
            final start = index * step;
            final end = (index + 1) * step;

            final anim = CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: Curves.easeOut),
            );

            final opacity = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(anim).value;
            final slide = Tween<double>(
              begin: 8.0,
              end: 0.0,
            ).animate(anim).value;
            final letterSpacing = Tween<double>(
              begin: 4.0,
              end: 0.0,
            ).animate(anim).value;

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0.0, slide),
                child: Text(
                  words[index],
                  style: (widget.style ?? const TextStyle()).copyWith(
                    letterSpacing: letterSpacing,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class ZoomInFlash extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const ZoomInFlash({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  State<ZoomInFlash> createState() => _ZoomInFlashState();
}

class _ZoomInFlashState extends State<ZoomInFlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_controller);

    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.8,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(scale: _scaleAnimation.value, child: widget.child),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: _flashAnimation.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ExpandingSubjectCard extends StatefulWidget {
  final Widget child;
  final bool isIconLeft;
  final Duration delay;
  final Duration duration;

  const ExpandingSubjectCard({
    super.key,
    required this.child,
    required this.isIconLeft,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1100), // slowly
  });

  @override
  State<ExpandingSubjectCard> createState() => _ExpandingSubjectCardState();
}

class _ExpandingSubjectCardState extends State<ExpandingSubjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  // Once set to true for the app session, cards never animate again
  static bool _hasAnimatedOnce = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    if (_hasAnimatedOnce) {
      // Already played once this session — snap to fully expanded instantly
      _controller.value = 1.0;
    } else {
      // First time: run the animation, then mark as done
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward().then((_) {
            _hasAnimatedOnce = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Height of the card is 128 (64 icon + 64 padding) + 16 outer bottom padding = 144
        const cardHeight = 128.0;
        const outerHeight = cardHeight + 16.0;

        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            // Animate width from cardHeight (square) to maxWidth
            final currentWidth =
                cardHeight + (maxWidth - cardHeight) * _expandAnimation.value;

            return Align(
              alignment: widget.isIconLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: SizedBox(
                width: currentWidth,
                height: outerHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: OverflowBox(
                    minWidth: maxWidth,
                    maxWidth: maxWidth,
                    minHeight: outerHeight,
                    maxHeight: outerHeight,
                    alignment: widget.isIconLeft
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
