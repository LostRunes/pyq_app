import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DonutSegment {
  final String label;
  final int value;
  final Color color;

  DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class InteractiveBalloonDonut extends StatefulWidget {
  final List<DonutSegment> segments;
  final int totalTarget;
  final String title;
  final String subtitle;

  const InteractiveBalloonDonut({
    super.key,
    required this.segments,
    required this.totalTarget,
    required this.title,
    required this.subtitle,
  });

  @override
  State<InteractiveBalloonDonut> createState() => _InteractiveBalloonDonutState();
}

class _InteractiveBalloonDonutState extends State<InteractiveBalloonDonut>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  int? _selectedIndex;
  Offset? _tooltipPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant InteractiveBalloonDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation if segments or target changed significantly
    if (oldWidget.segments.length != widget.segments.length ||
        oldWidget.totalTarget != widget.totalTarget) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
    final localPos = details.localPosition;
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    final distance = sqrt(dx * dx + dy * dy);
    final radius = min(constraints.maxWidth / 2, constraints.maxHeight / 2) - 10;
    
    // Check if the tap is within the donut ring area
    if (distance < radius - 20 || distance > radius + 20) {
      setState(() {
        _selectedIndex = null;
      });
      return;
    }

    // Calculate angle from -pi/2 (top)
    double angle = atan2(dy, dx);
    double angleFromTop = angle + pi / 2;
    if (angleFromTop < 0) {
      angleFromTop += 2 * pi;
    }

    // Determine which segment was tapped
    double currentAngle = 0.0;
    int? tappedIndex;

    for (int i = 0; i < widget.segments.length; i++) {
      final segment = widget.segments[i];
      if (segment.value <= 0) continue;
      
      final sweep = 2 * pi * (segment.value / widget.totalTarget);
      if (angleFromTop >= currentAngle && angleFromTop <= currentAngle + sweep) {
        tappedIndex = i;
        break;
      }
      currentAngle += sweep;
    }

    setState(() {
      _selectedIndex = tappedIndex;
      if (tappedIndex != null) {
        // Position tooltip at the center of the tapped segment's arc
        final segment = widget.segments[tappedIndex];
        double currentArcStart = 0.0;
        for (int i = 0; i < tappedIndex; i++) {
          if (widget.segments[i].value > 0) {
            currentArcStart += 2 * pi * (widget.segments[i].value / widget.totalTarget);
          }
        }
        final segmentSweep = 2 * pi * (segment.value / widget.totalTarget);
        final midAngle = currentArcStart + (segmentSweep / 2) - pi / 2;
        
        // Offset tooltip outward from the arc center
        final tooltipRadius = radius - 15;
        _tooltipPosition = Offset(
          center.dx + tooltipRadius * cos(midAngle),
          center.dy + tooltipRadius * sin(midAngle),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.segments.isNotEmpty 
        ? widget.segments.first.color 
        : const Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B4B).withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? primaryColor.withOpacity(0.15)
              : primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = min(constraints.maxWidth, 120.0);
              return SizedBox(
                height: size,
                width: size,
                child: GestureDetector(
                  onTapDown: (details) => _handleTapDown(details, BoxConstraints.tight(Size(size, size))),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(size, size),
                            painter: _BalloonDonutPainter(
                              segments: widget.segments,
                              totalTarget: widget.totalTarget,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.1),
                              selectedIndex: _selectedIndex,
                              animationValue: _progressAnimation.value,
                            ),
                          );
                        },
                      ),
                      // Center Stats
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.subtitle.split(' ').first,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                widget.subtitle.contains(' ') 
                                    ? widget.subtitle.substring(widget.subtitle.indexOf(' ') + 1).toUpperCase()
                                    : 'SOLVED',
                                style: GoogleFonts.outfit(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Interactive Tooltip Overlay
                      if (_selectedIndex != null && _tooltipPosition != null)
                        Positioned(
                          left: max(4.0, min(_tooltipPosition!.dx - 65.0, size - 134.0)),
                          top: max(4.0, min(_tooltipPosition!.dy - 20.0, size - 44.0)),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1A3C),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.segments[_selectedIndex!].color.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${widget.segments[_selectedIndex!].label} → ${widget.segments[_selectedIndex!].value} Solved',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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

class _BalloonDonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final int totalTarget;
  final Color backgroundColor;
  final int? selectedIndex;
  final double animationValue;

  _BalloonDonutPainter({
    required this.segments,
    required this.totalTarget,
    required this.backgroundColor,
    required this.selectedIndex,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    const strokeWidthNormal = 12.0;
    const strokeWidthSelected = 16.0;

    // Draw background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthNormal
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (segments.isEmpty || totalTarget <= 0) return;

    double currentAngle = -pi / 2;
    double lastTipAngle = -pi / 2;
    Color lastActiveColor = segments.first.color;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.value <= 0) continue;

      final isSelected = (i == selectedIndex);
      final sweepAngle = 2 * pi * (segment.value / totalTarget) * animationValue;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Selected segment glow shadow
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = segment.color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidthSelected + 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawArc(rect, currentAngle, sweepAngle, false, shadowPaint);
      }

      final progressPaint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidthSelected : strokeWidthNormal;

      // Draw rounded arc segment
      progressPaint.strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        currentAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      currentAngle += sweepAngle;
      lastTipAngle = currentAngle;
      lastActiveColor = segment.color;
    }

    // Draw balloon-like bubble indicator at the tip of the entire progress
    if (animationValue > 0 && currentAngle != -pi / 2) {
      final tipX = center.dx + radius * cos(lastTipAngle);
      final tipY = center.dy + radius * sin(lastTipAngle);

      final tipPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final tipShadow = Paint()
        ..color = lastActiveColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(tipX, tipY), 8, tipShadow);
      canvas.drawCircle(Offset(tipX, tipY), 6, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonDonutPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.segments != segments ||
        oldDelegate.totalTarget != totalTarget ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
