import 'package:flutter/material.dart';

class StudyTogetherSkeleton extends StatefulWidget {
  final String type; // 'community', 'personal', 'subject', 'lobby'

  const StudyTogetherSkeleton.community({super.key}) : type = 'community';
  const StudyTogetherSkeleton.personal({super.key}) : type = 'personal';
  const StudyTogetherSkeleton.subject({super.key}) : type = 'subject';
  const StudyTogetherSkeleton.lobby({super.key}) : type = 'lobby';

  @override
  State<StudyTogetherSkeleton> createState() => _StudyTogetherSkeletonState();
}

class _StudyTogetherSkeletonState extends State<StudyTogetherSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox(
    bool isDark,
    double height,
    double width, {
    double radius = 8,
    bool isCircle = false,
  }) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey[800]!.withOpacity(0.4) 
            : Colors.grey[300]!.withOpacity(0.5),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.35 + (_animation.value * 0.45);
        return Opacity(
          opacity: opacity,
          child: _buildSkeletonBody(isDark),
        );
      },
    );
  }

  Widget _buildSkeletonBody(bool isDark) {
    switch (widget.type) {
      case 'community':
        return SizedBox(
          height: 154,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            padding: const EdgeInsets.only(top: 8),
            itemBuilder: (context, index) {
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    _shimmerBox(isDark, 74, 74, isCircle: true),
                    const SizedBox(height: 8),
                    _shimmerBox(isDark, 12, 60),
                    const SizedBox(height: 6),
                    _shimmerBox(isDark, 10, 40),
                  ],
                ),
              );
            },
          ),
        );
      case 'lobby':
        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1428) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3F2654) : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _shimmerBox(isDark, 26, 26, radius: 6),
                            _shimmerBox(isDark, 18, 70, radius: 12),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _shimmerBox(isDark, 16, 140),
                        const SizedBox(height: 8),
                        _shimmerBox(isDark, 12, 180),
                        const SizedBox(height: 6),
                        _shimmerBox(isDark, 12, 100),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shimmerBox(isDark, 10, 80),
                        _shimmerBox(isDark, 10, 40),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      case 'subject':
        return SizedBox(
          height: 190,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 90 / 220,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191125) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF381F4C) : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    _shimmerBox(isDark, 34, 34, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _shimmerBox(isDark, 14, 110),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _shimmerBox(isDark, 6, 6, isCircle: true),
                              const SizedBox(width: 6),
                              _shimmerBox(isDark, 10, 70),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      case 'personal':
      default:
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1428) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3F2654) : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  _shimmerBox(isDark, 34, 34, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _shimmerBox(isDark, 14, 120)),
                            _shimmerBox(isDark, 16, 50, radius: 10),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _shimmerBox(isDark, 6, 6, isCircle: true),
                            const SizedBox(width: 6),
                            _shimmerBox(isDark, 10, 70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
    }
  }
}
