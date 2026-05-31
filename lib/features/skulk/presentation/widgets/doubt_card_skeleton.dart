import 'dart:math';
import 'package:flutter/material.dart';

/// Animated shimmer skeleton that mirrors the real DoubtCard shape.
class DoubtCardSkeleton extends StatefulWidget {
  const DoubtCardSkeleton({super.key});

  @override
  State<DoubtCardSkeleton> createState() => _DoubtCardSkeletonState();
}

class _DoubtCardSkeletonState extends State<DoubtCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.4 + (_animation.value * 0.35);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Opacity(
            opacity: opacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    _shimmerBox(isDark, 36, 36, isCircle: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(isDark, 12, 120),
                          const SizedBox(height: 5),
                          _shimmerBox(isDark, 10, 80),
                        ],
                      ),
                    ),
                    _shimmerBox(isDark, 22, 60, radius: 20),
                  ],
                ),
                const SizedBox(height: 12),

                // Subject chip
                _shimmerBox(isDark, 22, 100, radius: 8),
                const SizedBox(height: 10),

                // Title lines
                _shimmerBox(isDark, 14, double.infinity),
                const SizedBox(height: 6),
                _shimmerBox(isDark, 14, 220),
                const SizedBox(height: 10),

                // Body preview lines
                _shimmerBox(isDark, 12, double.infinity),
                const SizedBox(height: 5),
                _shimmerBox(isDark, 12, double.infinity),
                const SizedBox(height: 5),
                _shimmerBox(isDark, 12, 180),
                const SizedBox(height: 12),

                // Tags row
                Row(
                  children: [
                    _shimmerBox(isDark, 20, 60, radius: 6),
                    const SizedBox(width: 6),
                    _shimmerBox(isDark, 20, 50, radius: 6),
                    const SizedBox(width: 6),
                    _shimmerBox(isDark, 20, 70, radius: 6),
                  ],
                ),

                const Divider(height: 24),

                // Actions row
                Row(
                  children: [
                    _shimmerBox(isDark, 26, 70, radius: 10),
                    const SizedBox(width: 16),
                    _shimmerBox(isDark, 26, 90, radius: 10),
                    const SizedBox(width: 16),
                    _shimmerBox(isDark, 26, 50, radius: 10),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerBox(bool isDark, double height, double width,
      {double radius = 6, bool isCircle = false}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius:
            isCircle ? BorderRadius.circular(height / 2) : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}
