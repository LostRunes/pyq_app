import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/topic.dart';
import '../core/providers.dart';

class TopicDetailSheet extends ConsumerWidget {
  final Topic topic;
  final double importanceProgress;

  const TopicDetailSheet({
    super.key,
    required this.topic,
    required this.importanceProgress,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resourcesAsync = ref.watch(topicResourcesProvider(topic.id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topic Overview',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(
                      value: importanceProgress,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getImportanceColor(importanceProgress, theme),
                      ),
                    ),
                  ),
                  Text(
                    '${(importanceProgress * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/questions',
                arguments: {
                  'topicId': topic.id,
                  'topicName': topic.name,
                },
              );
            },
            icon: const Icon(Icons.description_rounded),
            label: const Text('See PYQs of this topic'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          resourcesAsync.when(
            data: (resources) {
              final ytResource = resources.where((r) => r.resourceType.toLowerCase().contains('youtube') || r.resourceType.toLowerCase().contains('yt')).firstOrNull;
              
              return ElevatedButton.icon(
                onPressed: ytResource != null ? () => _launchUrl(ytResource.url) : null,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: Text(ytResource != null ? 'YT Resource: ${ytResource.title}' : 'No YT Resource Available'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading resources: $e'),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getImportanceColor(double progress, ThemeData theme) {
    if (progress > 0.7) return Colors.red.shade400;
    if (progress > 0.4) return Colors.orange.shade400;
    return theme.colorScheme.primary;
  }
}
