import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';
import '../models/pyq_source.dart';
import '../models/image_item.dart';
import '../services/supabase_service.dart';

import '../core/providers.dart';
import '../widgets/solution_sheet.dart';


class QuestionDetailScreen extends ConsumerWidget {
  final String questionId;
  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionDetailProvider(questionId));
    final pyqAsync = ref.watch(pyqSourcesProvider(questionId));
    final imagesAsync = ref.watch(imagesProvider(questionId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Detail'),
      ),
      body: questionAsync.when(
        data: (question) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Metadata Tags
              pyqAsync.when(
                data: (pyqs) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pyqs.expand((pyq) => [
                    _buildMetaTag(context, '${pyq.examType} ${pyq.year}', Theme.of(context).colorScheme.primary.withOpacity(0.1), Theme.of(context).colorScheme.primary),
                    _buildMetaTag(context, '${pyq.season}', Theme.of(context).colorScheme.secondary.withOpacity(0.1), Theme.of(context).colorScheme.secondary),
                    _buildMetaTag(context, pyq.questionNumber, Theme.of(context).colorScheme.tertiary.withOpacity(0.2), Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ]).toList(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              // Main Question Card (Paper-like)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        question.questionText,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    imagesAsync.when(
                      data: (images) => images.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 32, left: 20, right: 20),
                              child: Column(
                                children: images
                                    .map((img) => Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: Image.network(
                                              img.imageUrl,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  height: 200,
                                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                                  child: const Center(child: CircularProgressIndicator()),
                                                );
                                              },
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('Error loading images: $e'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // AI Solve Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SolutionSheet(question: question.questionText),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  label: Text(
                    'Solve with AI Buddy',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMetaTag(BuildContext context, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

