import 'package:flutter/material.dart';

class SpeakingIndicator extends StatefulWidget {
  final Widget child;
  final bool isSpeaking;
  final Color glowColor;

  const SpeakingIndicator({
    super.key,
    required this.child,
    required this.isSpeaking,
    this.glowColor = const Color(0xFF10B981), // Emerald/Green
  });

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _animation = Tween<double>(begin: 2.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSpeaking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
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
      animation: _animation,
      builder: (context, child) {
        final shadowWidth = widget.isSpeaking ? _animation.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (widget.isSpeaking)
                BoxShadow(
                  color: widget.glowColor.withOpacity(0.5),
                  blurRadius: shadowWidth,
                  spreadRadius: shadowWidth / 3,
                ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
