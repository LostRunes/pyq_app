import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/segmented_toggle.dart';
import '../../../../services/pdf_service.dart';
import '../../data/models/topic.dart';
import '../providers/pyq_providers.dart';
import 'topic_card.dart';
import 'topic_detail_sheet.dart';

class TopicTab extends ConsumerStatefulWidget {
  final String subjectId;

  const TopicTab({super.key, required this.subjectId});

  @override
  ConsumerState<TopicTab> createState() => _TopicTabState();
}

class _TopicTabState extends ConsumerState<TopicTab> {
  String _sortMode = 'Sequential'; // Default to Sequential

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(dashboardTopicsProvider(widget.subjectId));

    return topicsAsync.when(
      data: (topics) {
        if (topics.isEmpty) {
          return const Center(child: Text('No topics found.'));
        }

        // Sort copy of topics based on current sort mode
        final List<Topic> displayedTopics = List<Topic>.from(topics);
        if (_sortMode == 'Importance') {
          displayedTopics.sort(
            (a, b) => b.importanceScore.compareTo(a.importanceScore),
          );
        }

        // Calculate max score for normalization
        final maxScore = topics.isEmpty
            ? 1.0
            : topics
                  .map((t) => t.importanceScore)
                  .reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Download All Button
            _buildDownloadButton(
              context,
              ref,
              displayedTopics.first.subjectId,
              'Topics',
            ),
            const SizedBox(height: 16),
            SegmentedToggle(
              options: const ['Sequential', 'Importance'],
              selectedOption: _sortMode,
              onSelected: (val) {
                setState(() {
                  _sortMode = val;
                });
              },
            ),
            const SizedBox(height: 16),
            ...displayedTopics.map((topic) {
              final progress = maxScore == 0
                  ? 0.0
                  : (topic.importanceScore / maxScore).clamp(0.0, 1.0);
              return TopicCard(
                topic: topic,
                importanceProgress: progress,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => TopicDetailSheet(
                      topic: topic,
                      importanceProgress: progress,
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
      loading: () => const TopicTabSkeleton(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    WidgetRef ref,
    String subjectId,
    String subjectName,
  ) {
    final isLoading = ref.watch(pdfLoadingProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading
            ? null
            : () async {
                ref.read(pdfLoadingProvider.notifier).setLoading(true);
                try {
                  final data = await ref.read(
                    subjectPdfDataProvider(subjectId).future,
                  );
                  final pdfService = PdfService();
                  final pdfBytes = await pdfService.generateSubjectPdf(
                    subjectName,
                    data,
                  );
                  await pdfService.downloadPdf(
                    pdfBytes,
                    '${subjectName.replaceAll(' ', '_')}_Full.pdf',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  ref.read(pdfLoadingProvider.notifier).setLoading(false);
                }
              },
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
        label: const Text(
          'Download all topic-wise PYQs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

class TopicTabSkeleton extends StatefulWidget {
  const TopicTabSkeleton({super.key});

  @override
  State<TopicTabSkeleton> createState() => _TopicTabSkeletonState();
}

class _TopicTabSkeletonState extends State<TopicTabSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.4 + (_animation.value * 0.35);
        return Opacity(
          opacity: opacity,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 4,
            itemBuilder: (context, idx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
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
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Container(
                            height: 16,
                            width: 16,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 12,
                            width: 30,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
