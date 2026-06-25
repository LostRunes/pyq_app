import 'package:flutter/material.dart';

class ParallaxPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  ParallaxPageRoute({required this.child, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Curves for smooth interpolation
            final entryCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic.flipped,
            );

            final exitCurve = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic.flipped,
            );

            // Incoming page: Slide in from the right
            final entrySlide = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(entryCurve);

            // Outgoing page: Slide out to the left slowly (parallax offset 0.3)
            final exitSlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(exitCurve);

            // Incoming page fades in slightly to avoid a harsh edge
            final entryFade = Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(entryCurve);

            return SlideTransition(
              position: exitSlide,
              child: SlideTransition(
                position: entrySlide,
                child: FadeTransition(
                  opacity: entryFade,
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 500),
        );
}
