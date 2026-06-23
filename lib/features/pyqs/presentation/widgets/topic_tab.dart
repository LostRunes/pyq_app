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
      loading: () => const Center(child: CircularProgressIndicator()),
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
