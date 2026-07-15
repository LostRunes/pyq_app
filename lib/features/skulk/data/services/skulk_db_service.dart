import 'package:supabase_flutter/supabase_flutter.dart';

class SkulkDbService {
  final SupabaseClient _client;

  SkulkDbService(this._client);

  // ----------------------------------------------------
  // DOUBTS (doubt_posts) Queries & Mutations
  // ----------------------------------------------------

  /// Fetches doubt posts from Supabase 2 with joined user profiles
  Future<List<Map<String, dynamic>>> fetchDoubts({
    String? subjectId,
    int? semester,
    String? searchQuery,
    String? filterType, // 'all', 'mine', 'unanswered', 'solved', 'hot'
    String? tagFilter, // single tag to filter by
    List<String>? subjectIds, // List of subjects for My Subjects feed
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client
        .from('doubt_posts')
        .select(
          '*, user_profiles(username, display_name, avatar_url, reputation)',
        );

    // 1. Text Search Filter (title or body ilike)
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final cleanSearch = '%${searchQuery.trim()}%';
      query = query.or('title.ilike.$cleanSearch,body.ilike.$cleanSearch');
    }

    // 2. Subject Filter
    if (subjectIds != null && subjectIds.isNotEmpty) {
      query = query.in_('subject_id', subjectIds);
    } else if (subjectId != null && subjectId.isNotEmpty) {
      query = query.eq('subject_id', subjectId);
    }

    // 3. Tag Filter (PostgreSQL array contains)
    if (tagFilter != null && tagFilter.isNotEmpty) {
      query = query.contains('tags', [tagFilter]);
    }

    // 4. Status Filters
    if (filterType == 'unanswered') {
      query = query.eq('answers_count', 0);
    } else if (filterType == 'solved') {
      query = query.eq('is_solved', true);
    } else if (filterType == 'mine') {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
    }

    // 5. Sorting & Pagination
    if (filterType == 'hot') {
      query = query.order('upvotes_count', ascending: false);
    } else {
      query = query.order('created_at', ascending: false);
    }

    final res = await query.range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  // ----------------------------------------------------
  // NOTIFICATIONS Helpers
  // ----------------------------------------------------

  /// Inserts a notification for a target user.
  Future<void> createNotification({
    required String userId,
    required String type,
    required String message,
    String? postId,
    String? answerId,
    String? actorUsername,
    String? actorDisplayName,
  }) async {
    final actorId = _client.auth.currentUser?.id;
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'message': message,
        'post_id': postId,
        'answer_id': answerId,
        'actor_id': actorId,
        'actor_username': actorUsername,
        'actor_display_name': actorDisplayName,
      });
    } catch (_) {
      // Notifications are non-critical — fail silently
    }
  }

  /// Fetches notifications for the current user, latest first.
  Future<List<Map<String, dynamic>>> fetchNotifications({
    int limit = 50,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Returns unread notification count for badge.
  Future<int> fetchUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;
    final res = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read', false);
    return (res as List).length;
  }

  /// Marks all notifications as read for current user.
  Future<void> markAllNotificationsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  /// Fetches a single doubt post by ID
  Future<Map<String, dynamic>?> fetchDoubtDetail(String doubtId) async {
    final res = await _client
        .from('doubt_posts')
        .select(
          '*, user_profiles(username, display_name, avatar_url, reputation)',
        )
        .eq('id', doubtId)
        .maybeSingle();
    return res;
  }

  /// Fetches a user_profiles row by user ID (for Skulk stats).
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final res = await _client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();
    return Map<String, dynamic>.from(res);
  }

  /// Inserts a new doubt
  Future<Map<String, dynamic>> createDoubt({
    required String title,
    required String body,
    required String subjectId,
    required List<String> tags,
    List<String> imageUrls = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to post doubts.');
    }

    final res = await _client
        .from('doubt_posts')
        .insert({
          'user_id': userId,
          'title': title,
          'body': body,
          'subject_id': subjectId,
          'tags': tags,
          'image_urls': imageUrls,
          'is_solved': false,
          'answers_count': 0,
          'comments_count': 0,
          'upvotes_count': 0,
          'views_count': 0,
        })
        .select()
        .single();

    return res;
  }

  /// Marks a doubt as solved or unsolved
  Future<void> setDoubtSolved(String doubtId, bool isSolved) async {
    await _client
        .from('doubt_posts')
        .update({'is_solved': isSolved})
        .eq('id', doubtId);
  }

  /// Edits an existing doubt
  Future<Map<String, dynamic>> editDoubt({
    required String doubtId,
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final res = await _client
        .from('doubt_posts')
        .update({'title': title, 'body': body, 'tags': tags})
        .eq('id', doubtId)
        .select()
        .single();
    return res;
  }

  /// Deletes a doubt post
  Future<void> deleteDoubt(String doubtId) async {
    await _client.from('doubt_posts').delete().eq('id', doubtId);
  }

  // ----------------------------------------------------
  // SOLUTIONS (answers) Queries & Mutations
  // ----------------------------------------------------

  /// Fetches solutions for a specific doubt post
  Future<List<Map<String, dynamic>>> fetchSolutions(String postId) async {
    final res = await _client
        .from('answers')
        .select(
          '*, user_profiles(username, display_name, avatar_url, reputation)',
        )
        .eq('post_id', postId)
        .order('is_accepted', ascending: false) // Accepted solution on top
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Inserts a new solution
  Future<Map<String, dynamic>> createSolution({
    required String postId,
    required String body,
    List<String> imageUrls = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to solve doubts.');
    }

    // 1. Insert answer (count increments automatically via DB trigger tr_sync_solution_stats)
    final res = await _client
        .from('answers')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'body': body,
          'image_urls': imageUrls,
          'upvotes_count': 0,
          'is_best': false,
          'is_accepted': false,
        })
        .select()
        .single();

    return res;
  }

  /// Deletes a solution
  Future<void> deleteSolution(String solutionId, String postId) async {
    // 1. Delete solution (count decrements automatically via DB trigger tr_sync_solution_stats)
    await _client.from('answers').delete().eq('id', solutionId);
  }

  /// Edits a solution
  Future<Map<String, dynamic>> editSolution(
    String solutionId,
    String body,
  ) async {
    final res = await _client
        .from('answers')
        .update({'body': body})
        .eq('id', solutionId)
        .select()
        .single();
    return res;
  }

  /// Toggles the accepted state of a solution and updates doubt post solved status
  Future<void> toggleSolutionAccepted(
    String solutionId,
    String postId,
    bool accept,
  ) async {
    await _client.rpc('accept_solution', params: {
      'solution_id': solutionId,
      'post_id': postId,
      'accept_val': accept,
    });
  }

  // ----------------------------------------------------
  // COMMENTS Queries & Mutations
  // ----------------------------------------------------

  /// Fetches comments for a specific doubt post (combines doubts & answers comments)
  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final res = await _client
        .from('comments')
        .select('*, user_profiles(username, display_name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Inserts a new comment
  Future<Map<String, dynamic>> createComment({
    required String postId,
    String? answerId,
    required String body,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User must be logged in to comment.');

    // 1. Insert comment (count increments automatically via DB trigger tr_sync_comment_stats)
    final res = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'answer_id': answerId,
          'user_id': userId,
          'body': body,
        })
        .select()
        .single();

    return res;
  }

  /// Edits an existing comment
  Future<Map<String, dynamic>> editComment(
    String commentId,
    String body,
  ) async {
    final res = await _client
        .from('comments')
        .update({'body': body})
        .eq('id', commentId)
        .select()
        .single();
    return res;
  }

  /// Deletes a comment
  Future<void> deleteComment(String commentId, String postId) async {
    // 1. Delete comment (count decrements automatically via DB trigger tr_sync_comment_stats)
    await _client.from('comments').delete().eq('id', commentId);
  }

  /// Creates a content report
  Future<void> createReport({
    String? postId,
    String? answerId,
    String? commentId,
    required String reason,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to report content.');
    }

    await _client.from('reports').insert({
      'reporter_id': userId,
      'post_id': postId,
      'answer_id': answerId,
      'comment_id': commentId,
      'reason': reason,
    });
  }

  // ----------------------------------------------------
  // VOTING Queries & Mutations (Upvotes Only)
  // ----------------------------------------------------

  /// Toggles upvote on a doubt post
  Future<int> toggleDoubtUpvote(String doubtId) async {
    final res = await _client.rpc('toggle_doubt_vote', params: {
      'doubt_id': doubtId,
    });
    return res as int;
  }

  /// Toggles upvote on a solution
  Future<int> toggleSolutionUpvote(String solutionId) async {
    final res = await _client.rpc('toggle_solution_vote', params: {
      'solution_id': solutionId,
    });
    return res as int;
  }

  /// Fetches all active vote records for the current user
  Future<List<Map<String, dynamic>>> fetchUserVotes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _client.from('votes').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(res);
  }
}
