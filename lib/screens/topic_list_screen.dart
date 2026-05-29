import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/topic.dart';
import '../services/supabase_service.dart';

import '../core/providers.dart';
import '../services/pdf_service.dart';
import '../widgets/loading_overlay.dart';

class TopicListScreen extends ConsumerWidget {
  final String subjectId;
  final String subjectName;
  const TopicListScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider(subjectId));
    final isLoading = ref.watch(pdfLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Download Subject PDF',
            onPressed: isLoading
                ? null
                : () async {
                    ref.read(pdfLoadingProvider.notifier).setLoading(true);

                    try {
                      final service = ref.read(supabaseServiceProvider);
                      final data = await service.getFullSubjectData(subjectId);

                      final pdfService = PdfService();
                      final pdfBytes = await pdfService.generateSubjectPdf(subjectName, data);

                      await pdfService.downloadPdf(pdfBytes, '${subjectName.replaceAll(' ', '_')}_Full.pdf');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      ref.read(pdfLoadingProvider.notifier).setLoading(false);
                    }
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: Image.asset('assets/images/raccoon.png'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diving into...',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Which topic shall we tackle?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: topicsAsync.when(
              data: (topics) => ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                itemCount: topics.length,
                itemBuilder: (context, i) {
                  final topic = topics[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/questions',
                          arguments: {
                            'topicId': topic.id,
                            'topicName': topic.name,
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Topic ${i + 1}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              topic.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              topic.summary ?? '',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    height: 1.6,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      if (isLoading)
        const LoadingOverlay(message: 'Generating your subject PDF... This might take a moment.'),
    ],
  ),
);
}
}
