import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/topic.dart';

class TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  final double importanceProgress; // Normalized 0.0 to 1.0

  const TopicCard({
    super.key,
    required this.topic,
    required this.onTap,
    required this.importanceProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topic.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Importance',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(importanceProgress * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: importanceProgress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getImportanceColor(importanceProgress, theme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getImportanceColor(double progress, ThemeData theme) {
    if (progress > 0.7) return Colors.red.shade400;
    if (progress > 0.4) return Colors.orange.shade400;
    return theme.colorScheme.primary;
  }
}
