import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../services/pdf_service.dart';
import '../widgets/loading_overlay.dart';

class QuestionListScreen extends ConsumerWidget {
  final String topicId;
  final String topicName;
  const QuestionListScreen({super.key, required this.topicId, required this.topicName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider(topicId));
    final isLoading = ref.watch(pdfLoadingProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(topicName),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Download PDF',
            onPressed: isLoading ? null : () async {
              ref.read(pdfLoadingProvider.notifier).setLoading(true);

              try {
                final service = ref.read(supabaseServiceProvider);
                final fullQuestions = await service.getQuestionsWithDetails(topicId);

                final pdfService = PdfService();
                final pdfBytes = await pdfService.generateTopicPdf(topicName, fullQuestions);

                await pdfService.downloadPdf(pdfBytes, '${topicName.replaceAll(' ', '_')}_Questions.pdf');
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
          questionsAsync.when(
            data: (questions) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: questions.length,
              itemBuilder: (context, i) {
                final question = questions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/question_detail',
                        arguments: {'questionId': question.id},
                      );
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(question.difficulty).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  question.difficulty.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getDifficultyColor(question.difficulty),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.questionText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
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
          if (isLoading)
            const LoadingOverlay(message: 'Preparing your topic PDF... ✨'),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade400;
      case 'medium':
        return Colors.orange.shade400;
      case 'hard':
        return Colors.red.shade400;
      default:
        return Colors.blue.shade400;
    }
  }
}
