import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _durationSeconds = 25 * 60; // Default: 25 minutes
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;

  late AnimationController _pulseController;

  final List<int> _presetMinutes = [15, 25, 45, 60];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _stopTimer(completed: true);
        }
      });
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer({bool completed = false}) {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      if (completed) {
        _secondsRemaining = _durationSeconds;
        _showCompletionDialog();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _durationSeconds;
    });
  }

  void _setDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _durationSeconds = minutes * 60;
      _secondsRemaining = _durationSeconds;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFFEC4899),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Focus Session Done!',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Amazing job staying focused. Take a short break, recharge, and get ready for the next round!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Awesome',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _durationSeconds > 0 ? _secondsRemaining / _durationSeconds : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Focus Timer',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                ),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Preset Duration Options
                AnimatedOpacity(
                  opacity: _isRunning ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: _isRunning,
                    child: Column(
                      children: [
                        Text(
                          'Choose Focus Duration',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _presetMinutes.map((minutes) {
                            final isSelected = _durationSeconds == minutes * 60;
                            return GestureDetector(
                              onTap: () => _setDuration(minutes),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEC4899)
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : const Color(0xFFEC4899).withOpacity(0.2),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFEC4899).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  '$minutes Min',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pulsing Circular Timer Card
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.03).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(_isRunning ? 0.15 : 0.06),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular Progress
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: const Color(0xFFEC4899).withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Countdown Text
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_secondsRemaining),
                              style: GoogleFonts.outfit(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isRunning ? 'FOCUS MODE ACTIVE' : 'STAY FOCUSED',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: const Color(0xFFEC4899),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Custom Time Adjuster
                AnimatedOpacity(
                  opacity: _isRunning ? 0.2 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: _isRunning,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            final currentMin = _durationSeconds ~/ 60;
                            if (currentMin > 1) {
                              _setDuration(currentMin - 1);
                            }
                          },
                          icon: const Icon(Icons.remove_rounded),
                          color: const Color(0xFFEC4899),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '${_durationSeconds ~/ 60} Min',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton.filledTonal(
                          onPressed: () {
                            final currentMin = _durationSeconds ~/ 60;
                            if (currentMin < 180) {
                              _setDuration(currentMin + 1);
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          color: const Color(0xFFEC4899),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controller Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRunning) ...[
                      // Pause Button
                      ElevatedButton.icon(
                        onPressed: _pauseTimer,
                        icon: const Icon(Icons.pause_rounded, color: Colors.white),
                        label: Text(
                          'Pause',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Reset Button
                      OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEC4899)),
                        label: Text(
                          'Reset',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEC4899)),
                          foregroundColor: const Color(0xFFEC4899),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ] else ...[
                      // Start Button
                      ElevatedButton.icon(
                        onPressed: _startTimer,
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: Text(
                          'Start Session',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
