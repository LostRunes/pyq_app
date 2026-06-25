import 'package:flutter/material.dart';
import '../styles/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String imagePath;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double imageHeight;

  const EmptyState({
    super.key,
    required this.imagePath,
    required this.title,
    this.subtitle,
    this.action,
    this.imageHeight = 130,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: imageHeight),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.input(context).copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.popupSubtitle(context).copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
