import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/pyq_providers.dart';

class ProgressTab extends ConsumerWidget {
  final String subjectId;

  const ProgressTab({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(dashboardTopicsProvider(subjectId));
    final progress = ref.watch(progressProvider);
    final trackedTopics = ref.watch(trackedTopicsProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        final _ = await ref.refresh(dashboardTopicsProvider(subjectId).future);
      },
      child: topicsAsync.when(
        data: (topics) {
          if (topics.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
                child: const Text('No topics to track.'),
              ),
            );
          }

          final trackedTopicsList = topics.where((t) => trackedTopics.contains(t.id)).toList();
          final completedCount = trackedTopicsList
              .where((t) => progress[t.id] ?? false)
              .length;
          final totalCount = trackedTopicsList.length;
          final percent = totalCount == 0 ? 0.0 : completedCount / totalCount;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: percent,
                            strokeWidth: 12,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          '${(percent * 100).toInt()}%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Overall Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      totalCount == 0
                          ? 'Tap "+" to add topics to track progress'
                          : '$completedCount of $totalCount topics completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Topics',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final topicIds = topics.map((t) => t.id).toList();
                        final allTracked = topics.every((t) => trackedTopics.contains(t.id));
                        ref.read(trackedTopicsProvider.notifier).setAllTracked(topicIds, !allTracked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              topics.isNotEmpty && topics.every((t) => trackedTopics.contains(t.id))
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Select All',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...topics.map((topic) {
                final isDone = progress[topic.id] ?? false;
                final isTracked = trackedTopics.contains(topic.id);

                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isTracked
                                ? Icons.remove_circle_outline_rounded
                                : Icons.add_circle_outline_rounded,
                            color: isTracked
                                ? theme.colorScheme.error.withValues(alpha: 0.7)
                                : theme.colorScheme.primary,
                          ),
                          tooltip: isTracked ? 'Remove topic' : 'Track topic',
                          onPressed: () {
                            ref
                                .read(trackedTopicsProvider.notifier)
                                .toggleTracked(topic.id);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topic.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: !isTracked
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                                  : isDone
                                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                      : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: isDone,
                          activeColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: !isTracked
                              ? null
                              : (val) {
                                  ref
                                      .read(progressProvider.notifier)
                                      .toggleProgress(topic.id);
                                },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: Text('Error: $e'),
          ),
        ),
      ),
    );
  }
}
