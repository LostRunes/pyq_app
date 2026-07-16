import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/focus_timer_provider.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _minutesController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<int> _presetMinutes = [15, 25, 45, 60];
  static const _accent = Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    final initialMins = ref.read(focusTimerProvider).durationSeconds ~/ 60;
    _minutesController = TextEditingController(text: initialMins.toString());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sync pulse animation on startup if already running
    if (ref.read(focusTimerProvider).isRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _endSessionPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Focus Session?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to end your current focus session? Your progress will not be saved.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(focusTimerProvider.notifier).endSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'End Session',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final int m = totalSeconds ~/ 60;
    final int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_rounded, color: _accent, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'Session Complete!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Great work staying focused! Take a break and come back stronger.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Awesome!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScrollPicker(int currentMinutes) {
    int tempMinutes = currentMinutes;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Focus Duration',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          tempMinutes = index + 1;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 180,
                        builder: (context, index) {
                          final isSelected = (index + 1) == tempMinutes;
                          return Center(
                            child: Text(
                              '${index + 1} minutes',
                              style: GoogleFonts.outfit(
                                fontSize: isSelected ? 20 : 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? _accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(focusTimerProvider.notifier).updateDuration(tempMinutes);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Confirm Duration',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerState = ref.watch(focusTimerProvider);
    final progress = timerState.durationSeconds > 0
        ? timerState.secondsRemaining / timerState.durationSeconds
        : 0.0;

    // React to changes in timer state (Sync Animation, Dialogs, Input synchronization)
    ref.listen<FocusTimerState>(focusTimerProvider, (previous, next) {
      if (previous?.isRunning != next.isRunning) {
        if (next.isRunning) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      }

      final newMinsStr = (next.durationSeconds ~/ 60).toString();
      if (_minutesController.text != newMinsStr && !next.hasStarted) {
        _minutesController.text = newMinsStr;
      }

      if (next.isCompleted && !(previous?.isCompleted ?? false)) {
        _showCompletionDialog();
        ref.read(focusTimerProvider.notifier).clearCompletionFlag();
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Focus Timer',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: timerState.hasStarted
            ? [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _endSessionPrompt,
                  tooltip: 'End Session',
                )
              ]
            : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!timerState.hasStarted) ...[
                        // SETUP MODE
                        const SizedBox(height: 20),
                        Text(
                          'Get ready to focus',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'ll minimize distractions. Set a duration and start your session.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Custom Input Box (Microsoft style)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Duration',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: 100, // Expanded to cleanly host 3 digits
                                          child: TextField(
                                            controller: _minutesController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center, // Center the digits!
                                            style: GoogleFonts.outfit(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w900,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false, // Disable default theme text-field background box
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                            onChanged: (val) {
                                              final parsed = int.tryParse(val) ?? 0;
                                              ref.read(focusTimerProvider.notifier).updateDuration(parsed);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            'mins',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 60,
                                width: 1,
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final m = timerState.durationSeconds ~/ 60;
                                      ref.read(focusTimerProvider.notifier).updateDuration(m + 1);
                                    },
                                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
                                    color: _accent,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final m = timerState.durationSeconds ~/ 60;
                                      if (m > 1) {
                                        ref.read(focusTimerProvider.notifier).updateDuration(m - 1);
                                      }
                                    },
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                                    color: _accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Scroll Picker Trigger Button
                        TextButton.icon(
                          onPressed: () => _showScrollPicker(timerState.durationSeconds ~/ 60),
                          icon: const Icon(Icons.unfold_more_rounded, color: _accent),
                          label: Text(
                            'Choose via scroll picker',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: _accent,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Preset Quick Options
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _presetMinutes.map((min) {
                            final selected = timerState.durationSeconds == min * 60;
                            return GestureDetector(
                              onTap: () => ref.read(focusTimerProvider.notifier).updateDuration(min),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? _accent : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: _accent.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  '$min Min',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => ref.read(focusTimerProvider.notifier).start(),
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                            label: Text(
                              'Start focus session',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ] else ...[
                        // ACTIVE TIMER MODE
                        const SizedBox(height: 40),

                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withOpacity(timerState.isRunning ? 0.18 : 0.07),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 230,
                                  height: 230,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 10,
                                    backgroundColor: _accent.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatTime(timerState.secondsRemaining),
                                      style: GoogleFonts.outfit(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      timerState.isRunning ? 'FOCUSING' : 'PAUSED',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: _accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Control Row (Visually Centered)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Left placeholder to keep Play/Pause perfectly centered
                            const SizedBox(width: 56),
                            const SizedBox(width: 24),
                            // Play/Pause Action Button
                            GestureDetector(
                              onTap: () {
                                if (timerState.isRunning) {
                                  ref.read(focusTimerProvider.notifier).pause();
                                } else {
                                  ref.read(focusTimerProvider.notifier).resume();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Reset Button
                            GestureDetector(
                              onTap: () => ref.read(focusTimerProvider.notifier).reset(),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: theme.colorScheme.onSurface,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // End Session
                        OutlinedButton.icon(
                          onPressed: _endSessionPrompt,
                          icon: const Icon(Icons.stop_rounded, color: _accent),
                          label: Text(
                            'End Session',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: _accent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _accent, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
