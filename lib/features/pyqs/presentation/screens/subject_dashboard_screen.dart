import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/services/analytics_service.dart';
import 'package:focus_fox/shared/widgets/loading_overlay.dart';
import '../../data/models/subject.dart';
import '../providers/pyq_providers.dart';
import '../widgets/topic_tab.dart';
import '../widgets/drive_explorer_tab.dart';
import '../widgets/link_tab.dart';
import '../widgets/progress_tab.dart';

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
    AnalyticsService.logSubjectOpened(widget.subject.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final topicsAsync = ref.watch(dashboardTopicsProvider(widget.subject.id));
    final hasTopics = topicsAsync.maybeWhen(
      data: (topics) => topics.isNotEmpty,
      orElse: () => true,
    );

    final hasPyqs =
        widget.subject.pyqDriveLink != null &&
        widget.subject.pyqDriveLink!.isNotEmpty;

    final hasNotes =
        widget.subject.notesDriveLink != null &&
        widget.subject.notesDriveLink!.isNotEmpty;

    final hasHandout =
        widget.subject.courseOutcomeLink != null &&
        widget.subject.courseOutcomeLink!.isNotEmpty;

    final tabs = [
      if (hasTopics) const Tab(text: "Topics"),
      if (hasPyqs) const Tab(text: "PYQs"),
      if (hasNotes) const Tab(text: "Notes"),
      if (hasHandout) const Tab(text: "Course Handout"),
      const Tab(text: "Progress"),
    ];

    final tabViews = [
      if (hasTopics) TopicTab(subjectId: widget.subject.id),
      if (hasPyqs)
        DriveExplorerTab(
          title: 'Subject PYQs',
          driveLink: widget.subject.pyqDriveLink,
        ),
      if (hasNotes)
        DriveExplorerTab(
          title: 'Subject Notes',
          driveLink: widget.subject.notesDriveLink,
        ),
      if (hasHandout)
        LinkTab(
          title: 'Course Handout',
          subtitle:
              'Access the official course handout, syllabus, and learning outcomes.',
          buttonLabel: 'Open Course Handout',
          icon: Icons.description_outlined,
          link: widget.subject.courseOutcomeLink,
          imagePath: 'assets/images/polar_bearr.png',
          subjectName: widget.subject.name,
        ),
      ProgressTab(subjectId: widget.subject.id),
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
                      LinkTab.openCourseHandout(
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
