import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:focus_fox/features/pyqs/presentation/providers/pyq_providers.dart';
import 'package:focus_fox/services/analytics_service.dart';
import 'package:focus_fox/features/pyqs/presentation/providers/question_pdf_provider.dart';
import 'package:focus_fox/features/pyqs/presentation/widgets/drive_file_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class QuestionDetailScreen extends ConsumerWidget {
  final String questionId;
  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionDetailProvider(questionId));
    final pyqAsync = ref.watch(pyqSourcesProvider(questionId));
    final imagesAsync = ref.watch(imagesProvider(questionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Question Detail'),
        actions: [
          questionAsync.when(
            data: (question) => IconButton(
              icon: const Icon(Icons.content_copy_rounded),
              tooltip: 'Copy Question Text',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: question.questionText));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Question text copied to clipboard!',
                        style: GoogleFonts.outfit(),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                ),
              )
            : null,
        child: SafeArea(
          child: questionAsync.when(
            data: (question) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AnalyticsService.logPyqViewed(question.difficulty, questionId);
              });
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Metadata Tags
                  pyqAsync.when(
                    data: (pyqs) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pyqs
                          .expand(
                            (pyq) => [
                              _buildMetaTag(
                                context,
                                '${pyq.examType} ${pyq.year}',
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                Theme.of(context).colorScheme.primary,
                              ),
                              _buildMetaTag(
                                context,
                                pyq.season,
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.1),
                                Theme.of(context).colorScheme.secondary,
                              ),
                              _buildMetaTag(
                                context,
                                pyq.questionNumber,
                                Theme.of(
                                  context,
                                ).colorScheme.tertiary.withOpacity(0.2),
                                Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ],
                          )
                          .toList(),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.06),
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
                                  padding: const EdgeInsets.only(
                                    bottom: 32,
                                    left: 20,
                                    right: 20,
                                  ),
                                  child: Column(
                                    children: images
                                        .map(
                                          (img) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              child: Image.network(
                                                img.imageUrl,
                                                loadingBuilder:
                                                    (context, child, progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      }
                                                      return Container(
                                                        height: 200,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .surfaceContainerHighest,
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        )
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
                  // Ask in Skulk Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/skulk_create',
                          arguments: {
                            'prefilledTitle': 'PYQ Doubt: ${question.questionText.length > 30 ? "${question.questionText.substring(0, 30)}..." : question.questionText}',
                            'prefilledBody': question.questionText,
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.forum_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Ask in Skulk',
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
                  Consumer(
                    builder: (context, ref, child) {
                      final matchAsync = ref.watch(questionPdfMatchProvider(questionId));
                      return matchAsync.when(
                        data: (result) {
                          if (result == null || result.allFiles.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          void openPdfFile(Map item) {
                            final webViewLink = item["webViewLink"] as String? ?? '';
                            if (webViewLink.isNotEmpty) {
                              final email = Supabase.instance.client.auth.currentUser?.email;
                              String finalUrl = webViewLink;
                              if (email != null && email.isNotEmpty) {
                                try {
                                  final uri = Uri.parse(webViewLink);
                                  final queryParams = Map<String, String>.from(uri.queryParameters);
                                  queryParams['authuser'] = email;
                                  finalUrl = uri.replace(queryParameters: queryParams).toString();
                                } catch (_) {}
                              }
                              launchUrl(
                                Uri.parse(finalUrl),
                                mode: LaunchMode.inAppBrowserView,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No link available for this file.')),
                              );
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Question Paper Files",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (result.matchedFiles.isNotEmpty) ...[
                                Text(
                                  "Recommended Matches",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...result.matchedFiles.map((file) {
                                  return DriveFileTile(
                                    item: file,
                                    onTap: () => openPdfFile(file),
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                              if (result.allFiles.length > result.matchedFiles.length) ...[
                                Text(
                                  "All Available Subject PYQ Papers",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...result.allFiles
                                    .where((file) => !result.matchedFiles.contains(file))
                                    .map((file) {
                                      return DriveFileTile(
                                        item: file,
                                        onTap: () => openPdfFile(file),
                                      );
                                    }),
                              ],
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTag(
    BuildContext context,
    String text,
    Color bgColor,
    Color textColor,
  ) {
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
