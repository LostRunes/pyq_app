import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/providers/prefs_provider.dart';
import '../../../subjects/presentation/providers/subjects_providers.dart';
import '../../data/models/comment.dart';
import '../../data/models/doubt.dart';
import '../../data/models/solution.dart';
import '../../data/services/skulk_db_service.dart';
import '../../data/repositories/skulk_repository.dart';

/// Raw Db Service Provider
final skulkDbServiceProvider = Provider<SkulkDbService>(
  (ref) => SkulkDbService(ref.watch(supabase2ClientProvider)),
);

/// Repository Provider (depends on SubjectsRepository and SkulkDbService)
final skulkRepositoryProvider = Provider<SkulkRepository>((ref) {
  final dbService = ref.watch(skulkDbServiceProvider);
  final subjectsRepository = ref.watch(subjectsRepositoryProvider);
  return SkulkRepository(
    dbService: dbService,
    subjectsRepository: subjectsRepository,
  );
});

/// Current filter type for Skulk feeds: 'all', 'subjects', 'unanswered', 'solved', 'hot'
class SkulkFeedFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void updateFilter(String filter) => state = filter;
}

// Not autoDispose — we want the filter to survive navigation to a detail screen
final skulkFeedFilterProvider =
    NotifierProvider<SkulkFeedFilterNotifier, String>(
      SkulkFeedFilterNotifier.new,
    );

/// Current search query string
class SkulkFeedSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateSearch(String query) => state = query;
}

// Not autoDispose — preserve search query when navigating away
final skulkFeedSearchProvider =
    NotifierProvider<SkulkFeedSearchNotifier, String>(
      SkulkFeedSearchNotifier.new,
    );

/// Selected subject filter for Skulk feed
class SkulkFeedSubjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateSubject(String? subjectId) => state = subjectId;
}

// Not autoDispose — preserve subject filter when navigating away
final skulkFeedSubjectProvider =
    NotifierProvider<SkulkFeedSubjectNotifier, String?>(
      SkulkFeedSubjectNotifier.new,
    );

/// Selected tag filter
class SkulkFeedTagNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateTag(String? tag) => state = tag;
}

// Not autoDispose — preserve tag filter when navigating away
final skulkFeedTagProvider = NotifierProvider<SkulkFeedTagNotifier, String?>(
  SkulkFeedTagNotifier.new,
);

// ---------------------------------------------------------------------------
// Paginated feed notifier — replaces the old simple FutureProvider
// ---------------------------------------------------------------------------

class SkulkFeedNotifier extends AsyncNotifier<List<Doubt>> {
  static const _pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<Doubt>> build() async {
    // Re-run when any filter changes
    final filter = ref.watch(skulkFeedFilterProvider);
    ref.watch(skulkFeedSearchProvider);
    ref.watch(skulkFeedSubjectProvider);
    ref.watch(skulkFeedTagProvider);

    // Also watch subjects provider if filter is 'subjects' to trigger automatic rebuilds
    if (filter == 'subjects') {
      final branchId = ref.watch(selectedBranchIdProvider);
      final semester = ref.watch(selectedSemesterProvider);
      if (branchId.isNotEmpty) {
        ref.watch(subjectsProvider((branchId: branchId, semester: semester)));
      }
    }

    // Reset pagination on filter change
    _offset = 0;
    _hasMore = true;
    _loadingMore = false;

    return _fetchPage(reset: true);
  }

  Future<List<Doubt>> _fetchPage({bool reset = false}) async {
    final repo = ref.read(skulkRepositoryProvider);
    final filter = ref.read(skulkFeedFilterProvider);
    final search = ref.read(skulkFeedSearchProvider);
    final subjectId = ref.read(skulkFeedSubjectProvider);
    final tag = ref.read(skulkFeedTagProvider);

    List<String>? mySubjectIds;
    if (filter == 'subjects') {
      final branchId = ref.read(selectedBranchIdProvider);
      final semester = ref.read(selectedSemesterProvider);
      if (branchId.isNotEmpty) {
        try {
          final subjects = await ref.read(subjectsProvider((branchId: branchId, semester: semester)).future);
          mySubjectIds = subjects.map((s) => s.id).toList();
        } catch (_) {
          mySubjectIds = [];
        }
      }
    }

    final page = await repo.getDoubts(
      filterType: filter,
      searchQuery: search,
      subjectId: subjectId,
      tagFilter: tag,
      subjectIds: mySubjectIds,
      limit: _pageSize,
      offset: _offset,
    );

    if (page.length < _pageSize) _hasMore = false;
    return page;
  }

  /// Load next page and append
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.value ?? [];
    _loadingMore = true;
    _offset += _pageSize;

    try {
      final next = await _fetchPage();
      state = AsyncData([...current, ...next]);
    } catch (e, st) {
      _offset -= _pageSize; // revert
      state = AsyncError(e, st);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    _loadingMore = false;
    state = const AsyncLoading();
    try {
      final page = await _fetchPage(reset: true);
      state = AsyncData(page);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> editDoubt({
    required String doubtId,
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final repo = ref.read(skulkRepositoryProvider);
    final updated = await repo.editDoubt(
      doubtId: doubtId,
      title: title,
      body: body,
      tags: tags,
    );
    // Locally update state if loaded
    if (state.hasValue) {
      final list = state.value!;
      state = AsyncData(
        list.map((d) => d.id == doubtId ? updated : d).toList(),
      );
    }
    ref.invalidate(doubtDetailProvider(doubtId));
  }

  Future<void> deleteDoubt(String doubtId) async {
    final repo = ref.read(skulkRepositoryProvider);
    await repo.deleteDoubt(doubtId);
    // Locally update state if loaded
    if (state.hasValue) {
      final list = state.value!;
      state = AsyncData(list.where((d) => d.id != doubtId).toList());
    }
    ref.invalidate(doubtDetailProvider(doubtId));
  }
}

final skulkFeedProvider = AsyncNotifierProvider<SkulkFeedNotifier, List<Doubt>>(
  SkulkFeedNotifier.new,
  isAutoDispose: true,
);

/// Active Upvotes Tracker Provider (Maps postId/answerId -> boolean upvoted)
class UserVotesNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    final repo = ref.watch(skulkRepositoryProvider);
    final rawVotes = await repo.getUserVotes();
    final Map<String, bool> voteMap = {};
    for (var v in rawVotes) {
      if (v['post_id'] != null) {
        voteMap[v['post_id'].toString()] = true;
      }
      if (v['answer_id'] != null) {
        voteMap[v['answer_id'].toString()] = true;
      }
    }
    return voteMap;
  }

  /// Optimistically toggles an upvote state for a doubt.
  /// Bails out early if votes haven't loaded yet to avoid incorrect toggling.
  Future<void> toggleDoubtVote(String doubtId) async {
    // Guard: don't toggle if vote map isn't loaded yet (prevents wrong-direction toggle)
    if (!state.hasValue) return;
    final repo = ref.read(skulkRepositoryProvider);
    final previousState = state.value!;
    final isUpvoted = previousState[doubtId] ?? false;

    // 1. Optimistic UI update for user votes map
    final updatedMap = Map<String, bool>.from(previousState);
    if (isUpvoted) {
      updatedMap.remove(doubtId);
    } else {
      updatedMap[doubtId] = true;
    }
    state = AsyncData(updatedMap);

    // 2. Optimistic count update in skulkFeedProvider
    final feedNotifier = ref.read(skulkFeedProvider.notifier);
    if (feedNotifier.state.hasValue) {
      final list = feedNotifier.state.value!;
      feedNotifier.state = AsyncData(
        list.map((d) {
          if (d.id == doubtId) {
            return d.copyWith(
              upvotesCount: (d.upvotesCount + (isUpvoted ? -1 : 1)).clamp(0, 999999),
            );
          }
          return d;
        }).toList(),
      );
    }

    // 3. Optimistic count update in doubtDetailProvider
    final detailNotifier = ref.read(doubtDetailProvider(doubtId).notifier);
    if (detailNotifier.state.hasValue) {
      final d = detailNotifier.state.value;
      if (d != null) {
        detailNotifier.state = AsyncData(
          d.copyWith(
            upvotesCount: (d.upvotesCount + (isUpvoted ? -1 : 1)).clamp(0, 999999),
          ),
        );
      }
    }

    try {
      final realCount = await repo.toggleDoubtUpvote(doubtId);

      // Update UI with actual synced count from server
      if (feedNotifier.state.hasValue) {
        final list = feedNotifier.state.value!;
        feedNotifier.state = AsyncData(
          list.map((d) {
            if (d.id == doubtId) {
              return d.copyWith(upvotesCount: realCount);
            }
            return d;
          }).toList(),
        );
      }

      if (detailNotifier.state.hasValue) {
        final d = detailNotifier.state.value;
        if (d != null) {
          detailNotifier.state = AsyncData(
            d.copyWith(upvotesCount: realCount),
          );
        }
      }
    } catch (_) {
      // Revert on error
      state = AsyncData(previousState);
      
      // Revert feed count
      if (feedNotifier.state.hasValue) {
        final list = feedNotifier.state.value!;
        feedNotifier.state = AsyncData(
          list.map((d) {
            if (d.id == doubtId) {
              return d.copyWith(
                upvotesCount: (d.upvotesCount + (isUpvoted ? 1 : -1)).clamp(0, 999999),
              );
            }
            return d;
          }).toList(),
        );
      }
      
      // Revert detail count
      if (detailNotifier.state.hasValue) {
        final d = detailNotifier.state.value;
        if (d != null) {
          detailNotifier.state = AsyncData(
            d.copyWith(
              upvotesCount: (d.upvotesCount + (isUpvoted ? 1 : -1)).clamp(0, 999999),
            ),
          );
        }
      }
    }
  }

  /// Optimistically toggles an upvote state for a solution
  Future<void> toggleSolutionVote(String solutionId, String doubtId) async {
    // Guard: don't toggle if vote map isn't loaded yet (prevents wrong-direction toggle)
    if (!state.hasValue) return;
    final repo = ref.read(skulkRepositoryProvider);
    final previousState = state.value!;
    final isUpvoted = previousState[solutionId] ?? false;

    // 1. Optimistic UI update for user votes map
    final updatedMap = Map<String, bool>.from(previousState);
    if (isUpvoted) {
      updatedMap.remove(solutionId);
    } else {
      updatedMap[solutionId] = true;
    }
    state = AsyncData(updatedMap);

    // 2. Optimistic solutions count update
    final solutionsNotifier = ref.read(solutionsNotifierProvider(doubtId).notifier);
    final solutionsList = solutionsNotifier.state;
    solutionsNotifier.state = solutionsList.map((s) {
      if (s.id == solutionId) {
        return s.copyWith(
          upvotesCount: (s.upvotesCount + (isUpvoted ? -1 : 1)).clamp(0, 999999),
        );
      }
      return s;
    }).toList();

    try {
      final realCount = await repo.toggleSolutionUpvote(solutionId);

      // Update UI with actual synced count from server
      final currentList = solutionsNotifier.state;
      solutionsNotifier.state = currentList.map((s) {
        if (s.id == solutionId) {
          return s.copyWith(upvotesCount: realCount);
        }
        return s;
      }).toList();
    } catch (_) {
      // Revert on error
      state = AsyncData(previousState);
      
      // Revert solution count
      final revertedList = solutionsNotifier.state;
      solutionsNotifier.state = revertedList.map((s) {
        if (s.id == solutionId) {
          return s.copyWith(
            upvotesCount: (s.upvotesCount + (isUpvoted ? 1 : -1)).clamp(0, 999999),
          );
        }
        return s;
      }).toList();
    }
  }
}

final userVotesProvider =
    AsyncNotifierProvider<UserVotesNotifier, Map<String, bool>>(
      UserVotesNotifier.new,
      isAutoDispose: true,
    );

/// Single Doubt detail thread loader (allows local state mutation for upvote counts)
class DoubtDetailNotifier extends Notifier<AsyncValue<Doubt?>> {
  DoubtDetailNotifier(this.doubtId);
  final String doubtId;

  @override
  AsyncValue<Doubt?> build() {
    _loadDoubt();
    return const AsyncValue.loading();
  }

  Future<void> _loadDoubt() async {
    try {
      final repo = ref.read(skulkRepositoryProvider);
      final res = await repo.getDoubtDetail(doubtId);
      state = AsyncValue.data(res);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final doubtDetailProvider =
    NotifierProvider.family<DoubtDetailNotifier, AsyncValue<Doubt?>, String>(
      DoubtDetailNotifier.new,
      isAutoDispose: true,
    );

/// Solutions notifier family to manage answers in a thread
class SolutionsNotifier extends Notifier<List<Solution>> {
  SolutionsNotifier(this.arg);
  final String arg;

  @override
  List<Solution> build() {
    _loadSolutions();
    return [];
  }

  Future<void> _loadSolutions() async {
    final repo = ref.read(skulkRepositoryProvider);
    try {
      final list = await repo.getSolutions(arg);
      state = list;
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _loadSolutions();
  }

  Future<void> addSolution(
    String body, {
    List<String> imageUrls = const [],
  }) async {
    final repo = ref.read(skulkRepositoryProvider);
    final newSol = await repo.createSolution(
      postId: arg,
      body: body,
      imageUrls: imageUrls,
    );
    state = [newSol, ...state];
    ref.invalidate(skulkFeedProvider);
    ref.invalidate(doubtDetailProvider(arg));
  }

  Future<void> deleteSolution(String solutionId) async {
    final repo = ref.read(skulkRepositoryProvider);
    await repo.deleteSolution(solutionId, arg);
    state = state.where((element) => element.id != solutionId).toList();
    ref.invalidate(skulkFeedProvider);
    ref.invalidate(doubtDetailProvider(arg));
  }

  Future<void> editSolution(String solutionId, String body) async {
    final repo = ref.read(skulkRepositoryProvider);
    final updated = await repo.editSolution(solutionId, body);
    state = state
        .map((s) => s.id == solutionId ? s.copyWith(body: updated.body) : s)
        .toList();
  }

  Future<void> toggleAcceptSolution(String solutionId, bool isAccepted) async {
    final repo = ref.read(skulkRepositoryProvider);
    await repo.toggleSolutionAccepted(solutionId, arg, isAccepted);

    // Refresh to reload accurate is_accepted values
    await _loadSolutions();
    ref.invalidate(skulkFeedProvider);
    ref.invalidate(doubtDetailProvider(arg));
  }
}

final solutionsNotifierProvider =
    NotifierProvider.family<SolutionsNotifier, List<Solution>, String>(
      SolutionsNotifier.new,
      isAutoDispose: true,
    );

/// Comments notifier family to manage one-level replies linked to a thread
class CommentsNotifier extends Notifier<List<Comment>> {
  CommentsNotifier(this.arg);
  final String arg;

  @override
  List<Comment> build() {
    _loadComments();
    return [];
  }

  Future<void> _loadComments() async {
    final repo = ref.read(skulkRepositoryProvider);
    try {
      final list = await repo.getComments(arg);
      state = list;
    } catch (_) {}
  }

  Future<void> addComment(String body, {String? answerId}) async {
    final repo = ref.read(skulkRepositoryProvider);
    final newComment = await repo.createComment(
      postId: arg,
      answerId: answerId,
      body: body,
    );
    state = [...state, newComment];
    ref.invalidate(skulkFeedProvider);
    ref.invalidate(doubtDetailProvider(arg));
  }

  Future<void> editComment(String commentId, String body) async {
    final repo = ref.read(skulkRepositoryProvider);
    final updated = await repo.editComment(commentId, body, arg);
    state = state.map((c) => c.id == commentId ? updated : c).toList();
  }

  Future<void> deleteComment(String commentId) async {
    final repo = ref.read(skulkRepositoryProvider);
    await repo.deleteComment(commentId, arg);
    state = state.where((c) => c.id != commentId).toList();
    ref.invalidate(skulkFeedProvider);
    ref.invalidate(doubtDetailProvider(arg));
  }
}

final commentsNotifierProvider =
    NotifierProvider.family<CommentsNotifier, List<Comment>, String>(
      CommentsNotifier.new,
      isAutoDispose: true,
    );
