import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return IconButton(
      onPressed: () {
        // Using the toggle method from our Notifier
        ref.read(themeModeProvider.notifier).toggle();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          themeMode == ThemeMode.light
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          key: ValueKey(themeMode),
        ),
      ),
    );
  }
}
