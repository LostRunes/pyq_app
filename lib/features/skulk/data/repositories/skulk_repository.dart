import '../../../../services/supabase_service.dart';
import '../models/comment.dart';
import '../models/doubt.dart';
import '../models/solution.dart';
import '../services/skulk_db_service.dart';

class SkulkRepository {
  final SkulkDbService _dbService;
  final SupabaseService _supabaseService;

  // In-memory cache for mapping subject ID to subject name (sourced from Supabase 1)
  final Map<String, String> _subjectCache = {};

  SkulkRepository({
    required SkulkDbService dbService,
    required SupabaseService supabaseService,
  })  : _dbService = dbService,
        _supabaseService = supabaseService;

  /// Ensures that all curriculum subjects are cached in memory for quick name mapping.
  /// Sources from Supabase 1 (the academic DB). subject_id in doubt_posts is stored
  /// as plain text — no FK — so no sync to Supabase 2 is needed.
  Future<void> _ensureSubjectCache() async {
    if (_subjectCache.isNotEmpty) return;
    try {
      final subjects = await _supabaseService.getAllSubjects();
      for (var s in subjects) {
        _subjectCache[s.id] = s.name;
      }
    } catch (_) {
      // Silent fallback if Supabase 1 is unavailable
    }
  }

  /// Resolves the subject name for a given subject ID.
  Future<String> getSubjectName(String subjectId) async {
    await _ensureSubjectCache();
    return _subjectCache[subjectId] ?? 'Unknown Subject';
  }

  /// Fetches a list of doubts, mapping their subject IDs to human-readable curriculum names.
  Future<List<Doubt>> getDoubts({
    String? subjectId,
    int? semester,
    String? searchQuery,
    String? filterType,
    int limit = 20,
    int offset = 0,
  }) async {
    await _ensureSubjectCache();

    final rawDoubts = await _dbService.fetchDoubts(
      subjectId: subjectId,
      semester: semester,
      searchQuery: searchQuery,
      filterType: filterType,
      limit: limit,
      offset: offset,
    );

    final List<Doubt> doubts = [];
    for (var raw in rawDoubts) {
      final subId = raw['subject_id']?.toString() ?? '';
      final subjectName = _subjectCache[subId] ?? 'Unknown Subject';
      doubts.add(Doubt.fromJson(raw, subjectName: subjectName));
    }
    return doubts;
  }

  /// Fetches a single doubt by ID with its resolved subject name.
  Future<Doubt?> getDoubtDetail(String doubtId) async {
    await _ensureSubjectCache();

    final raw = await _dbService.fetchDoubtDetail(doubtId);
    if (raw == null) return null;

    final subId = raw['subject_id']?.toString() ?? '';
    final subjectName = _subjectCache[subId] ?? 'Unknown Subject';
    return Doubt.fromJson(raw, subjectName: subjectName);
  }

  /// Creates a new doubt. subject_id is stored as plain text; no FK sync needed.
  Future<Doubt> createDoubt({
    required String title,
    required String body,
    required String subjectId,
    required List<String> tags,
  }) async {
    await _ensureSubjectCache();

    final raw = await _dbService.createDoubt(
      title: title,
      body: body,
      subjectId: subjectId,
      tags: tags,
    );

    final subjectName = _subjectCache[subjectId] ?? 'Unknown Subject';
    return Doubt.fromJson(raw, subjectName: subjectName);
  }

  /// Toggles resolved solved status of a doubt.
  Future<void> setDoubtSolved(String doubtId, bool isSolved) async {
    await _dbService.setDoubtSolved(doubtId, isSolved);
  }

  /// Fetches all solutions (answers) for a doubt, ordered by accepted status then newest.
  Future<List<Solution>> getSolutions(String postId) async {
    final rawList = await _dbService.fetchSolutions(postId);
    return rawList.map((e) => Solution.fromJson(e)).toList();
  }

  /// Publishes a new solution (answer) for a doubt.
  Future<Solution> createSolution({
    required String postId,
    required String body,
  }) async {
    final raw = await _dbService.createSolution(postId: postId, body: body);
    
    // Fetch newly inserted answer with author profiles
    final solutions = await getSolutions(postId);
    return solutions.firstWhere((element) => element.id == raw['id'], orElse: () => Solution.fromJson(raw));
  }

  /// Deletes a solution.
  Future<void> deleteSolution(String solutionId, String postId) async {
    await _dbService.deleteSolution(solutionId, postId);
  }

  /// Edits a solution.
  Future<Solution> editSolution(String solutionId, String body) async {
    final raw = await _dbService.editSolution(solutionId, body);
    return Solution.fromJson(raw);
  }

  /// Toggles a solution as accepted.
  Future<void> toggleSolutionAccepted(String solutionId, String postId, bool accept) async {
    await _dbService.toggleSolutionAccepted(solutionId, postId, accept);
  }

  /// Fetches all comments for a doubt.
  Future<List<Comment>> getComments(String postId) async {
    final rawList = await _dbService.fetchComments(postId);
    return rawList.map((e) => Comment.fromJson(e)).toList();
  }

  /// Publishes a new comment.
  Future<Comment> createComment({
    required String postId,
    String? answerId,
    required String body,
  }) async {
    final raw = await _dbService.createComment(postId: postId, answerId: answerId, body: body);
    
    // Fetch comments to ensure full profile join gets loaded
    final comments = await getComments(postId);
    return comments.firstWhere((element) => element.id == raw['id'], orElse: () => Comment.fromJson(raw));
  }

  /// Toggles an upvote on a doubt.
  Future<int> toggleDoubtUpvote(String doubtId) async {
    return await _dbService.toggleDoubtUpvote(doubtId);
  }

  /// Toggles an upvote on a solution.
  Future<int> toggleSolutionUpvote(String solutionId) async {
    return await _dbService.toggleSolutionUpvote(solutionId);
  }

  /// Fetches the current user's vote history.
  Future<List<Map<String, dynamic>>> getUserVotes() async {
    return await _dbService.fetchUserVotes();
  }
}
