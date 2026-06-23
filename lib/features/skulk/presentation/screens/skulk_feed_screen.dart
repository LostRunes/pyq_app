import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../subjects/presentation/providers/subjects_providers.dart';
import '../providers/skulk_providers.dart';
import '../widgets/doubt_card.dart';
import '../widgets/doubt_card_skeleton.dart';

class SkulkFeedScreen extends ConsumerStatefulWidget {
  final String branchId;
  final int semester;

  const SkulkFeedScreen({
    super.key,
    required this.branchId,
    required this.semester,
  });

  @override
  ConsumerState<SkulkFeedScreen> createState() => _SkulkFeedScreenState();
}

class _SkulkFeedScreenState extends ConsumerState<SkulkFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(skulkFeedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilter = ref.watch(skulkFeedFilterProvider);

    // Watch all curriculum subjects for the student's current branch & sem
    final subjectsAsync = ref.watch(
      subjectsProvider((branchId: widget.branchId, semester: widget.semester)),
    );

    // Watch the active doubts feed list from state provider
    final doubtsAsync = ref.watch(skulkFeedProvider);
    final feedNotifier = ref.read(skulkFeedProvider.notifier);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141414)
          : const Color(0xFFF9F9F9),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isDark
                  ? 'assets/images/skulk_bg_dark.jpg'
                  : 'assets/images/skulk_bg3.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              isDark
                  ? Colors.black.withOpacity(0.10)
                  : Colors.white.withOpacity(0.45),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await feedNotifier.refresh();
            },
            color: Theme.of(context).colorScheme.primary,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 12),

                // New horizontally aligned controls row
                _buildControlRow(context, isDark, subjectsAsync),

                const SizedBox(height: 8),

                // Main feed content
                doubtsAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      6,
                      (_) => const DoubtCardSkeleton(),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load doubts.',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$err',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => feedNotifier.refresh(),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.outfit(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (doubtsList) {
                    // Apply user's academic "My Subjects" filter in-memory if selected
                    var displayDoubts = doubtsList;
                    if (activeFilter == 'subjects' && subjectsAsync.hasValue) {
                      final currentSubjectIds = subjectsAsync.value!
                          .map((e) => e.id)
                          .toSet();
                      displayDoubts = doubtsList
                          .where((d) => currentSubjectIds.contains(d.subjectId))
                          .toList();
                    }

                    if (displayDoubts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: _buildEmptyState(context, isDark, activeFilter),
                      );
                    }

                    return Column(
                      children: [
                        ...displayDoubts.map((doubt) {
                          return DoubtCard(
                            doubt: doubt,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/skulk_detail',
                                arguments: {
                                  'doubtId': doubt.id,
                                  'branchId': widget.branchId,
                                  'semester': widget.semester,
                                },
                              );
                            },
                          );
                        }),
                        if (feedNotifier.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (!feedNotifier.hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                "You've seen it all! 👀",
                                style: GoogleFonts.outfit(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            height: 80,
                          ), // Padding to avoid FAB overlapping feed items
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/skulk_create',
            arguments: {
              'branchId': widget.branchId,
              'semester': widget.semester,
            },
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String filter) {
    final Map<String, (String, String, IconData)> states = {
      'unanswered': (
        'No unanswered doubts yet 👀',
        'All questions have been answered!',
        Icons.check_circle_outline_rounded,
      ),
      'solved': (
        'No solved doubts yet 🏆',
        'Be the first solver!',
        Icons.emoji_events_outlined,
      ),
      'subjects': (
        'Nothing from your subjects 📚',
        'Your classmates haven\'t posted here yet.',
        Icons.library_books_outlined,
      ),
      'hot': (
        'Nothing trending right now 🔥',
        'Check back soon — the feed is warming up.',
        Icons.local_fire_department_outlined,
      ),
      'all': (
        'The feed is empty 🎙️',
        'Be the first to break the silence!',
        Icons.bubble_chart_outlined,
      ),
    };

    final (title, subtitle, icon) = states[filter] ?? states['all']!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(
    BuildContext context,
    bool isDark,
    AsyncValue<List<dynamic>> subjectsAsync,
  ) {
    final activeFilter = ref.watch(skulkFeedFilterProvider);
    final selectedSubjectId = ref.watch(skulkFeedSubjectProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Filter Dropdown
          Expanded(
            flex: 12,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeFilter,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.filter_list_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Doubts', style: GoogleFonts.outfit()),
                    ),
                    DropdownMenuItem(
                      value: 'subjects',
                      child: Text('My Subjects', style: GoogleFonts.outfit()),
                    ),
                    DropdownMenuItem(
                      value: 'solved',
                      child: Text('Solved', style: GoogleFonts.outfit()),
                    ),
                    DropdownMenuItem(
                      value: 'unanswered',
                      child: Text('Unanswered', style: GoogleFonts.outfit()),
                    ),
                    DropdownMenuItem(
                      value: 'hot',
                      child: Text('Hot', style: GoogleFonts.outfit()),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      if (val == 'subjects') {
                        ref.read(skulkFeedSubjectProvider.notifier).state =
                            null;
                      }
                      ref.read(skulkFeedFilterProvider.notifier).state = val;
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Subject Dropdown
          Expanded(
            flex: 13,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                ),
              ),
              child: subjectsAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) =>
                    Text('Error', style: GoogleFonts.outfit(fontSize: 11)),
                data: (subjects) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedSubjectId,
                      isExpanded: true,
                      hint: Text(
                        'All Subjects',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: Colors.grey,
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Subjects',
                            style: GoogleFonts.outfit(),
                          ),
                        ),
                        ...subjects.map((sub) {
                          return DropdownMenuItem<String?>(
                            value: sub.id,
                            child: Text(
                              sub.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        ref.read(skulkFeedSubjectProvider.notifier).state = val;
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Study Together Button
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/study-together');
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0083B0).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Study Room',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

// ---------------------------------------------------------------------------
// Notification Bell Widget (Public)
// ---------------------------------------------------------------------------
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countAsync = ref.watch(unreadCountProvider);

    final count = countAsync.value ?? 0;

    return IconButton(
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        backgroundColor: Colors.redAccent,
        textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        child: Icon(
          Icons.notifications_outlined,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      onPressed: () {
        Navigator.pushNamed(context, '/skulk_notifications');
      },
    );
  }
}

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(skulkRepositoryProvider);
  return repo.getUnreadNotificationCount();
});
