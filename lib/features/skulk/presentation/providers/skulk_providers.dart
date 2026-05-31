import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/models/comment.dart';
import '../../data/models/doubt.dart';
import '../../data/models/solution.dart';
import '../../data/services/skulk_db_service.dart';
import '../../data/repositories/skulk_repository.dart';

/// Raw Db Service Provider
final skulkDbServiceProvider = Provider<SkulkDbService>((ref) => SkulkDbService());

/// Repository Provider (depends on SupabaseService and SkulkDbService)
final skulkRepositoryProvider = Provider<SkulkRepository>((ref) {
  final dbService = ref.watch(skulkDbServiceProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SkulkRepository(
    dbService: dbService,
    supabaseService: supabaseService,
  );
});

/// Current filter type for Skulk feeds: 'all', 'mine', 'unanswered', 'solved', 'hot'
class SkulkFeedFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final skulkFeedFilterProvider = NotifierProvider<SkulkFeedFilterNotifier, String>(
  SkulkFeedFilterNotifier.new,
  isAutoDispose: true,
);

/// Current search query string
class SkulkFeedSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final skulkFeedSearchProvider = NotifierProvider<SkulkFeedSearchNotifier, String>(
  SkulkFeedSearchNotifier.new,
  isAutoDispose: true,
);

/// Selected subject filter for Skulk feed
class SkulkFeedSubjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

final skulkFeedSubjectProvider = NotifierProvider<SkulkFeedSubjectNotifier, String?>(
  SkulkFeedSubjectNotifier.new,
  isAutoDispose: true,
);

/// Dynamic Doubts Feed Provider
final skulkFeedProvider = FutureProvider<List<Doubt>>((ref) async {
  final repo = ref.watch(skulkRepositoryProvider);
  final filter = ref.watch(skulkFeedFilterProvider);
  final search = ref.watch(skulkFeedSearchProvider);
  final subjectId = ref.watch(skulkFeedSubjectProvider);

  return repo.getDoubts(
    filterType: filter,
    searchQuery: search,
    subjectId: subjectId,
  );
}, isAutoDispose: true);

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

  /// Optimistically toggles an upvote state for a doubt
  Future<void> toggleDoubtVote(String doubtId) async {
    final repo = ref.read(skulkRepositoryProvider);
    final previousState = state.value ?? {};
    final isUpvoted = previousState[doubtId] ?? false;

    // 1. Optimistic UI update
    final updatedMap = Map<String, bool>.from(previousState);
    if (isUpvoted) {
      updatedMap.remove(doubtId);
    } else {
      updatedMap[doubtId] = true;
    }
    state = AsyncData(updatedMap);

    try {
      await repo.toggleDoubtUpvote(doubtId);
      // Refresh feed in background to sync count
      ref.invalidate(skulkFeedProvider);
      ref.invalidate(doubtDetailProvider(doubtId));
    } catch (_) {
      // Revert on error
      state = AsyncData(previousState);
    }
  }

  /// Optimistically toggles an upvote state for a solution
  Future<void> toggleSolutionVote(String solutionId, String doubtId) async {
    final repo = ref.read(skulkRepositoryProvider);
    final previousState = state.value ?? {};
    final isUpvoted = previousState[solutionId] ?? false;

    // 1. Optimistic UI update
    final updatedMap = Map<String, bool>.from(previousState);
    if (isUpvoted) {
      updatedMap.remove(solutionId);
    } else {
      updatedMap[solutionId] = true;
    }
    state = AsyncData(updatedMap);

    try {
      await repo.toggleSolutionUpvote(solutionId);
      // Refresh solutions notifier for this doubt to sync count
      ref.read(solutionsNotifierProvider(doubtId).notifier).refresh();
    } catch (_) {
      // Revert on error
      state = AsyncData(previousState);
    }
  }
}

final userVotesProvider = AsyncNotifierProvider<UserVotesNotifier, Map<String, bool>>(
  UserVotesNotifier.new,
  isAutoDispose: true,
);

/// Single Doubt detail thread loader
final doubtDetailProvider = FutureProvider.family<Doubt?, String>((ref, doubtId) async {
  final repo = ref.watch(skulkRepositoryProvider);
  return repo.getDoubtDetail(doubtId);
}, isAutoDispose: true);

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

  Future<void> addSolution(String body) async {
    final repo = ref.read(skulkRepositoryProvider);
    final newSol = await repo.createSolution(postId: arg, body: body);
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
    state = state.map((s) => s.id == solutionId ? s.copyWith(body: updated.body) : s).toList();
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

final solutionsNotifierProvider = NotifierProvider.family<SolutionsNotifier, List<Solution>, String>(
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
    final newComment = await repo.createComment(postId: arg, answerId: answerId, body: body);
    state = [...state, newComment];
    ref.invalidate(skulkFeedProvider);
    ref.invalidate(doubtDetailProvider(arg));
  }
}

final commentsNotifierProvider = NotifierProvider.family<CommentsNotifier, List<Comment>, String>(
  CommentsNotifier.new,
  isAutoDispose: true,
);
