import 'package:flutter/material.dart';

class MascotAvatarSelector extends StatelessWidget {
  final String selectedAvatarPath;
  final ValueChanged<String> onSelected;

  final List<Map<String, String>> _mascots = const [
    {'name': 'Pikachu', 'path': 'assets/images/pikachu.png'},
    {'name': 'Fox', 'path': 'assets/images/lil_fox.png'},
    {'name': 'Panda', 'path': 'assets/images/panda.png'},
    {'name': 'Cat', 'path': 'assets/images/cat.png'},
    {'name': 'Octopus', 'path': 'assets/images/lil_octopus.png'},
    {'name': 'Owl', 'path': 'assets/images/owl.png'},
    {'name': 'Polar Bear', 'path': 'assets/images/polar_bearr.png'},
    {'name': 'Raccoon', 'path': 'assets/images/raccoon.png'},
    {'name': 'Toothless', 'path': 'assets/images/toothless.png'},
    {'name': 'Shark', 'path': 'assets/images/sleepy-shark.png'},
  ];

  const MascotAvatarSelector({
    super.key,
    required this.selectedAvatarPath,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mascots.length,
        itemBuilder: (context, index) {
          final mascot = _mascots[index];
          final path = mascot['path']!;
          final isSelected = selectedAvatarPath == path;
          return GestureDetector(
            onTap: () => onSelected(path),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: isDark
                    ? const Color(0xFF1E193C)
                    : Colors.amber.shade50.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    path,
                    fit: BoxFit.contain,
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
