import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers.dart';
import '../providers/skulk_providers.dart';
import '../widgets/doubt_card.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    hintText: 'Search doubts, title or safe tags...',
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

            // Main feed content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(skulkFeedProvider);
                },
                color: Theme.of(context).colorScheme.primary,
                child: doubtsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
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
                        ],
                      ),
                    ),
                  ),
                  data: (doubtsList) {
                    // Apply user's academic "My Subjects" filter in-memory if selected
                    var displayDoubts = doubtsList;
                    if (activeFilter == 'subjects' && subjectsAsync.hasValue) {
                      final currentSubjectIds = subjectsAsync.value!.map((e) => e.id).toSet();
                      displayDoubts = doubtsList.where((d) => currentSubjectIds.contains(d.subjectId)).toList();
                    }

                    if (displayDoubts.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bubble_chart_outlined,
                                  size: 60,
                                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No doubts found here.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Be the first to post a doubt!',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: displayDoubts.length,
                      itemBuilder: (context, index) {
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
                    );
                  },
                ),
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

  Widget _buildFilterChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilter = ref.watch(skulkFeedFilterProvider);

    final filters = [
      {'id': 'all', 'label': 'All Doubts', 'icon': Icons.public_rounded},
      {'id': 'subjects', 'label': 'My Subjects', 'icon': Icons.library_books_rounded},
      {'id': 'solved', 'label': 'Solved', 'icon': Icons.check_circle_rounded},
      {'id': 'unanswered', 'label': 'Unanswered', 'icon': Icons.help_outline_rounded},
      {'id': 'hot', 'label': 'Hot', 'icon': Icons.local_fire_department_rounded},
    ];

    return SizedBox(
      height: 38,
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
                // If switching filter, reset specific subject dropdown filters to 'All'
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

    // Only show subject filter dropdown if "All Doubts", "Solved", "Unanswered", or "Hot" is selected.
    // If "My Subjects" filter is selected, subject list is already scoped.
    if (activeFilter == 'subjects') return const SizedBox.shrink();

    return subjectsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subjects) {
        if (subjects.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                'Filter by Subject:',
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
}
