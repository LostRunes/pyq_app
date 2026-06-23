import 'package:flutter/material.dart';
import '../styles/app_text_styles.dart';

class SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = selectedOption == option;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  option,
                  style: AppTextStyles.input(context).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
