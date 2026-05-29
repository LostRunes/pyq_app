import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/providers.dart';

class SolutionSheet extends ConsumerStatefulWidget {
  final String question;

  const SolutionSheet({super.key, required this.question});

  @override
  ConsumerState<SolutionSheet> createState() => _SolutionSheetState();
}

class _SolutionSheetState extends ConsumerState<SolutionSheet> {
  String? answer;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAnswer();
  }

  Future<void> fetchAnswer() async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final res = await aiService.solveQuestion(widget.question).timeout(
        const Duration(seconds: 25),
      );

      if (mounted) {
        setState(() {
          answer = res;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString().contains('Timeout') 
              ? "The AI is taking too long. Please try again! ⏳" 
              : "Oops! Something went wrong while solving. 🛠️";
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'AI Study Buddy',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Content
          Flexible(
            child: loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          'Thinking deeply... 🧠',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  loading = true;
                                  error = null;
                                });
                                fetchAnswer();
                              },
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: MarkdownBody(
                          data: answer ?? "",
                          styleSheet: MarkdownStyleSheet(
                            h2: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            p: GoogleFonts.outfit(
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                            listBullet: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
