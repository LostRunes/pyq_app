import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilter = ref.watch(skulkFeedFilterProvider);

    // Watch all curriculum subjects for the student's current branch & sem
    final subjectsAsync = ref.watch(subjectsProvider((
      branchId: widget.branchId,
      semester: widget.semester,
    )));

    // Watch the active doubts feed list from state provider
    final doubtsAsync = ref.watch(skulkFeedProvider);
    final feedNotifier = ref.read(skulkFeedProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header row with title + Study Together + notification bell
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Skulk 🦊',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/study-together',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Study Together',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NotificationBell(),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF202020) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: GoogleFonts.outfit(fontSize: 14),
                  onChanged: (val) {
                    ref.read(skulkFeedSearchProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search doubts, title or tags...',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(skulkFeedSearchProvider.notifier).state = '';
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Horizontal Filter Chips row
            _buildFilterChips(context),

            // Subject Filter dropdown row (if active)
            _buildSubjectSelectorRow(context, subjectsAsync),

            // Tag filter chips
            _buildTagFilterRow(context),

            // Main feed content
            Expanded(
              child: doubtsAsync.when(
                loading: () => ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: 6,
                  itemBuilder: (_, __) => const DoubtCardSkeleton(),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load doubts.',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$err',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => feedNotifier.refresh(),
                          child: Text('Try Again', style: GoogleFonts.outfit()),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (doubtsList) {
                  // Apply user's academic "My Subjects" filter in-memory if selected
                  var displayDoubts = doubtsList;
                  if (activeFilter == 'subjects' && subjectsAsync.hasValue) {
                    final currentSubjectIds =
                        subjectsAsync.value!.map((e) => e.id).toSet();
                    displayDoubts = doubtsList
                        .where((d) => currentSubjectIds.contains(d.subjectId))
                        .toList();
                  }

                  if (displayDoubts.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                        _buildEmptyState(context, isDark, activeFilter),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await feedNotifier.refresh();
                    },
                    color: Theme.of(context).colorScheme.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemCount: displayDoubts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == displayDoubts.length) {
                          // Footer
                          if (feedNotifier.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          if (!feedNotifier.hasMore) {
                            return Padding(
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
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final doubt = displayDoubts[index];
                        return DoubtCard(
                          doubt: doubt,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/skulk_detail',
                              arguments: doubt.id,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Ask Doubt',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String filter) {
    final Map<String, (String, String, IconData)> states = {
      'unanswered': ('No unanswered doubts yet 👀', 'All questions have been answered!', Icons.check_circle_outline_rounded),
      'solved': ('No solved doubts yet 🏆', 'Be the first solver!', Icons.emoji_events_outlined),
      'subjects': ('Nothing from your subjects 📚', 'Your classmates haven\'t posted here yet.', Icons.library_books_outlined),
      'hot': ('Nothing trending right now 🔥', 'Check back soon — the feed is warming up.', Icons.local_fire_department_outlined),
      'all': ('The feed is empty 🎙️', 'Be the first to break the silence!', Icons.bubble_chart_outlined),
    };

    final (title, subtitle, icon) = states[filter] ?? states['all']!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: isDark ? Colors.grey[800] : Colors.grey[300]),
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

  Widget _buildFilterChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilter = ref.watch(skulkFeedFilterProvider);

    final filters = [
      {'id': 'all', 'label': 'All Doubts', 'icon': Icons.public_rounded},
      {'id': 'subjects', 'label': 'My Subjects', 'icon': Icons.library_books_rounded},
      {'id': 'solved', 'label': 'Solved', 'icon': Icons.check_circle_rounded},
      {'id': 'unanswered', 'label': 'Unanswered', 'icon': Icons.help_outline_rounded},
      {'id': 'hot', 'label': 'Hot 🔥', 'icon': Icons.local_fire_department_rounded},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = activeFilter == f['id'];

          return ChoiceChip(
            label: Row(
              children: [
                Icon(
                  f['icon'] as IconData,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                Text(
                  f['label'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                if (f['id'] == 'subjects') {
                  ref.read(skulkFeedSubjectProvider.notifier).state = null;
                }
                ref.read(skulkFeedFilterProvider.notifier).state = f['id'] as String;
              }
            },
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.grey[850]! : Colors.grey[300]!),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectSelectorRow(BuildContext context, AsyncValue<List<dynamic>> subjectsAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilter = ref.watch(skulkFeedFilterProvider);
    final selectedSubjectId = ref.watch(skulkFeedSubjectProvider);

    if (activeFilter == 'subjects') return const SizedBox.shrink();

    return subjectsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subjects) {
        if (subjects.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                'Subject:',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedSubjectId,
                      hint: Text(
                        'All Subjects',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      style: GoogleFonts.outfit(fontSize: 11),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Subjects',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        ...subjects.map((sub) {
                          return DropdownMenuItem<String?>(
                            value: sub.id,
                            child: Text(
                              '${sub.name} (${sub.code})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.grey[300] : Colors.grey[800],
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (subjectId) {
                        ref.read(skulkFeedSubjectProvider.notifier).state = subjectId;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagFilterRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTag = ref.watch(skulkFeedTagProvider);
    final doubtsAsync = ref.watch(skulkFeedProvider);

    // Collect all unique tags from current feed
    final tags = <String>{};
    if (doubtsAsync.hasValue) {
      for (final d in doubtsAsync.value!) {
        tags.addAll(d.tags);
      }
    }
    if (tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Clear tag button
          if (activeTag != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => ref.read(skulkFeedTagProvider.notifier).state = null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.close_rounded, size: 12, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text('#$activeTag',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ...tags.take(15).map((tag) {
            final isActive = activeTag == tag;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  ref.read(skulkFeedTagProvider.notifier).state =
                      isActive ? null : tag;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                        : (isDark ? const Color(0xFF252525) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                          : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Bell Widget
// ---------------------------------------------------------------------------
class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countAsync = ref.watch(_unreadCountProvider);

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

final _unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(skulkRepositoryProvider);
  return repo.getUnreadNotificationCount();
});
