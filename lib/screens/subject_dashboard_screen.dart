import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../widgets/topic_card.dart';
import '../widgets/topic_detail_sheet.dart';
import '../services/pdf_service.dart';
import '../widgets/loading_overlay.dart';

class SubjectDashboardScreen extends ConsumerStatefulWidget {
  final Subject subject;

  const SubjectDashboardScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectDashboardScreen> createState() =>
      _SubjectDashboardScreenState();
}

class _SubjectDashboardScreenState
    extends ConsumerState<SubjectDashboardScreen> {
  bool _showHint = false;
  double _hintOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _triggerHint();
  }

  void _triggerHint() {
    if (widget.subject.courseOutcomeLink != null &&
        widget.subject.courseOutcomeLink!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _showHint = true;
            _hintOpacity = 1.0;
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _hintOpacity = 0.0);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _showHint = false);
              });
            }
          });
        }
      });
    }
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(pdfLoadingProvider);
    final theme = Theme.of(context);

    final hasHandout =
        widget.subject.courseOutcomeLink != null &&
        widget.subject.courseOutcomeLink!.isNotEmpty;

    return DefaultTabController(
      length: 4,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.subject.name),
              actions: [
                if (hasHandout)
                  IconButton(
                    icon: const Icon(Icons.description_outlined),
                    tooltip: 'Course Handout',
                    onPressed: () =>
                        _launchUrl(widget.subject.courseOutcomeLink),
                  ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: "PYQs"),
                  Tab(text: "Topics"),
                  Tab(text: "Notes"),
                  Tab(text: "Progress"),
                ],
              ),
            ),
            body: Stack(
              children: [
                TabBarView(
                  children: [
                    _LinkTab(
                      title: 'Subject PYQs',
                      subtitle:
                          'Access the complete Google Drive folder for previous year questions.',
                      buttonLabel: 'Open PYQ Drive',
                      icon: Icons.folder_shared_rounded,
                      link: widget.subject.pyqDriveLink,
                      imagePath: 'assets/images/panda.png',
                    ),
                    _TopicTab(subjectId: widget.subject.id),
                    _LinkTab(
                      title: 'Subject Notes',
                      subtitle:
                          'Access study materials, lecture notes, and hand-written guides.',
                      buttonLabel: 'Open Notes Drive',
                      icon: Icons.menu_book_rounded,
                      link: widget.subject.notesDriveLink,
                      imagePath: 'assets/images/raccoon.png',
                    ),
                    _ProgressTab(subjectId: widget.subject.id),
                  ],
                ),
                if (isLoading)
                  const LoadingOverlay(
                    message: 'Generating your subject PDF... ✨',
                  ),
              ],
            ),
          ),
          if (_showHint && hasHandout)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              top:
                  MediaQuery.of(context).padding.top +
                  (_hintOpacity == 1.0 ? 42 : 62),
              right: 12,
              child: AnimatedOpacity(
                opacity: _hintOpacity,
                duration: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.arrow_upward,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'View Course Handout',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final String? link;
  final String imagePath;

  const _LinkTab({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    this.link,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 180),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (link != null && link!.isNotEmpty)
                  ? () async {
                      final Uri url = Uri.parse(link!);
                      if (!await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open the link.'),
                          ),
                        );
                      }
                    }
                  : null,
              icon: Icon(icon),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTab extends ConsumerWidget {
  final String subjectId;

  const _TopicTab({required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(dashboardTopicsProvider(subjectId));

    return topicsAsync.when(
      data: (topics) {
        if (topics.isEmpty)
          return const Center(child: Text('No topics found.'));

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
              topics.first.subjectId,
              'Topics',
            ),
            const SizedBox(height: 16),
            ...topics.map((topic) {
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
            }).toList(),
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
                  final service = ref.read(supabaseServiceProvider);
                  final data = await service.getFullSubjectData(subjectId);
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

class _ProgressTab extends ConsumerWidget {
  final String subjectId;

  const _ProgressTab({required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(dashboardTopicsProvider(subjectId));
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);

    return topicsAsync.when(
      data: (topics) {
        if (topics.isEmpty)
          return const Center(child: Text('No topics to track.'));

        final completedCount = topics
            .where((t) => progress[t.id] ?? false)
            .length;
        final totalCount = topics.length;
        final percent = totalCount == 0 ? 0.0 : completedCount / totalCount;

        return Column(
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
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
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
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final isDone = progress[topic.id] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone
                            ? theme.colorScheme.primary.withOpacity(0.3)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        topic.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
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
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
