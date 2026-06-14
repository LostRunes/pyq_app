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
import '../utils/drive_utils.dart';
import 'pdf_viewer_screen.dart';
import 'image_viewer_screen.dart';

class SubjectDashboardScreen extends ConsumerStatefulWidget {
  final Subject subject;

  const SubjectDashboardScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectDashboardScreen> createState() =>
      _SubjectDashboardScreenState();
}

class _SubjectDashboardScreenState
    extends ConsumerState<SubjectDashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasHandout =
        widget.subject.courseOutcomeLink != null &&
        widget.subject.courseOutcomeLink!.isNotEmpty;

    final tabs = [
      const Tab(text: "Topics"),
      const Tab(text: "PYQs"),
      const Tab(text: "Notes"),
      if (hasHandout) const Tab(text: "Course Handout"),
      const Tab(text: "Progress"),
    ];

    final tabViews = [
      _TopicTab(subjectId: widget.subject.id),
      _DriveExplorerTab(
        title: 'Subject PYQs',
        driveLink: widget.subject.pyqDriveLink,
      ),
      _DriveExplorerTab(
        title: 'Subject Notes',
        driveLink: widget.subject.notesDriveLink,
      ),
      if (hasHandout)
        _LinkTab(
          title: 'Course Handout',
          subtitle:
              'Access the official course handout, syllabus, and learning outcomes.',
          buttonLabel: 'Open Course Handout',
          icon: Icons.description_outlined,
          link: widget.subject.courseOutcomeLink,
          imagePath: 'assets/images/lil_fox.png',
          subjectName: widget.subject.name,
        ),
      _ProgressTab(subjectId: widget.subject.id),
    ];

    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.subject.name,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'Course Handout',
              onPressed:
                  (widget.subject.courseOutcomeLink != null &&
                      widget.subject.courseOutcomeLink!.isNotEmpty)
                  ? () {
                      openCourseHandout(
                        context,
                        widget.subject.courseOutcomeLink!,
                        widget.subject.name,
                      );
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No course handout linked for this subject.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                  ),
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: isDark
                      ? Colors.white60
                      : Colors.black54,
                  tabs: tabs,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    children: [
                      TabBarView(children: tabViews),
                      Consumer(
                        builder: (context, ref, child) {
                          final isLoading = ref.watch(pdfLoadingProvider);
                          if (isLoading) {
                            return const LoadingOverlay(
                              message: 'Generating your subject PDF... ✨',
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final String subjectName;

  const _LinkTab({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    this.link,
    required this.imagePath,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        // Simulate network delay for premium visual feedback on pull-to-refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(32.0),
          alignment: Alignment.center,
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
                      ? () {
                          openCourseHandout(context, link!, subjectName);
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
        ),
      ),
    );
  }
}

class _DriveExplorerTab extends ConsumerStatefulWidget {
  final String title;
  final String? driveLink;

  const _DriveExplorerTab({required this.title, required this.driveLink});

  @override
  ConsumerState<_DriveExplorerTab> createState() => _DriveExplorerTabState();
}

class _DriveExplorerTabState extends ConsumerState<_DriveExplorerTab> {
  Future<void> openItem(Map item) async {
    final isFolder = item["mimeType"] == "application/vnd.google-apps.folder";

    if (isFolder) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(
                item["name"],
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
            body: SafeArea(
              child: _DriveExplorerTab(
                title: item["name"],
                driveLink:
                    "https://drive.google.com/drive/folders/${item["id"]}",
              ),
            ),
          ),
        ),
      );
    } else {
      final fileId = item["id"] as String? ?? '';
      final name = item["name"] as String? ?? 'File';
      final mimeType = item["mimeType"] as String? ?? '';
      final webViewLink = item["webViewLink"] as String? ?? '';

      if (mimeType.contains("pdf") && fileId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: "https://drive.google.com/uc?export=download&id=$fileId",
              title: name,
              webViewLink: webViewLink,
            ),
          ),
        );
      } else if (mimeType.startsWith("image/") && fileId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(
              imageUrl: "https://drive.google.com/uc?export=view&id=$fileId",
              title: name,
              webViewLink: webViewLink,
            ),
          ),
        );
      } else {
        if (webViewLink.isNotEmpty) {
          final messenger = ScaffoldMessenger.of(context);
          final Uri url = Uri.parse(webViewLink);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not open the file link.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content;

    if (widget.driveLink == null || widget.driveLink!.isEmpty) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/owl.png', height: 130),
                const SizedBox(height: 16),
                Text(
                  "No Drive folder linked.",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final folderId = extractFolderId(widget.driveLink!);
      final filesAsync = ref.watch(driveFolderContentsProvider(folderId));

      content = filesAsync.when(
        data: (data) {
          final List<dynamic> sortedData = List<dynamic>.from(data)
            ..sort((a, b) {
              final aFolder =
                  a["mimeType"] == "application/vnd.google-apps.folder";
              final bFolder =
                  b["mimeType"] == "application/vnd.google-apps.folder";
              if (aFolder == bFolder) return 0;
              return aFolder ? -1 : 1;
            });

          if (sortedData.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/sleepy-shark.png', height: 130),
                    const SizedBox(height: 16),
                    Text(
                      "This folder is empty.",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final item = sortedData[index];
              final isFolder =
                  item["mimeType"] == "application/vnd.google-apps.folder";

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: (() {
                    final mimeType = item["mimeType"] as String? ?? '';
                    final thumbnail = item["thumbnailLink"] as String?;
                    IconData leadingIcon = Icons.description_rounded;
                    Color iconColor = Colors.blue;

                    if (isFolder) {
                      leadingIcon = Icons.folder_rounded;
                      iconColor = Colors.amber;
                    } else if (mimeType.contains("pdf")) {
                      leadingIcon = Icons.picture_as_pdf_rounded;
                      iconColor = Colors.redAccent;
                    } else if (mimeType.startsWith("image/")) {
                      leadingIcon = Icons.image_rounded;
                      iconColor = Colors.teal;
                    } else if (mimeType.contains("word") ||
                        mimeType.contains("document")) {
                      leadingIcon = Icons.article_rounded;
                      iconColor = Colors.blue;
                    } else if (mimeType.contains("spreadsheet") ||
                        mimeType.contains("excel") ||
                        mimeType.contains("sheet")) {
                      leadingIcon = Icons.table_chart_rounded;
                      iconColor = Colors.green;
                    } else if (mimeType.contains("presentation") ||
                        mimeType.contains("powerpoint")) {
                      leadingIcon = Icons.slideshow_rounded;
                      iconColor = Colors.orange;
                    }

                    if (thumbnail != null && !isFolder) {
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.3,
                            ),
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildFallbackIcon(leadingIcon, iconColor),
                        ),
                      );
                    }

                    return _buildFallbackIcon(leadingIcon, iconColor);
                  })(),
                  title: Text(
                    item["name"] ?? "Unnamed Item",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onTap: () => openItem(item),
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                "Fetching files from Google Drive...",
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/sad_raccoon.png', height: 130),
                  const SizedBox(height: 16),
                  Text(
                    "Something went wrong",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(driveFolderContentsProvider(folderId));
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.driveLink != null && widget.driveLink!.isNotEmpty) {
      final folderId = extractFolderId(widget.driveLink!);
      content = RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(driveFolderContentsProvider(folderId).future);
        },
        child: content,
      );
    }

    return Container(
      decoration: isDark
          ? const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/darktheme_bg.png'),
                fit: BoxFit.cover,
              ),
            )
          : null,
      child: content,
    );
  }

  Widget _buildFallbackIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _TopicTab extends ConsumerStatefulWidget {
  final String subjectId;

  const _TopicTab({required this.subjectId});

  @override
  ConsumerState<_TopicTab> createState() => _TopicTabState();
}

class _TopicTabState extends ConsumerState<_TopicTab> {
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
            _buildSortingToggle(context),
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
            }).toList(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSortingToggle(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _sortMode = 'Sequential';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _sortMode == 'Sequential'
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Sequential',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _sortMode == 'Sequential'
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _sortMode = 'Importance';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _sortMode == 'Importance'
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Importance',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _sortMode == 'Importance'
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh topics lists/progress data
        await ref.refresh(dashboardTopicsProvider(subjectId).future);
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
                        decoration: isDone ? TextDecoration.lineThrough : null,
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
              }).toList(),
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

void openCourseHandout(BuildContext context, String url, String title) {
  if (url.contains("drive.google.com")) {
    String? id;
    final fileIdRegExp = RegExp(r'/file/d/([^/]+)');
    final match = fileIdRegExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      id = match.group(1);
    } else {
      final idRegExp = RegExp(r'[?&]id=([^&]+)');
      final matchId = idRegExp.firstMatch(url);
      if (matchId != null && matchId.groupCount >= 1) {
        id = matchId.group(1);
      }
    }
    if (id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            pdfUrl: "https://drive.google.com/uc?export=download&id=$id",
            title: title,
            webViewLink: url,
          ),
        ),
      );
      return;
    }
  }

  // Fallback to launching externally if it's a non-drive link or fails to extract id
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((
    e,
  ) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open handout link: $e')),
      );
    }
  });
}
