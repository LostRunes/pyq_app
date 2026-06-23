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

          final completedCount = topics
              .where((t) => progress[t.id] ?? false)
              .length;
          final totalCount = topics.length;
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
                      '$completedCount of $totalCount topics completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              ...topics.map((topic) {
                final isDone = progress[topic.id] ?? false;

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
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      topic.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    value: isDone,
                    activeColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onChanged: (val) {
                      ref
                          .read(progressProvider.notifier)
                          .toggleProgress(topic.id);
                    },
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
