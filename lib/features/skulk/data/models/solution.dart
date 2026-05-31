class Solution {
  final String id;
  final String postId;
  final String userId;
  final String body;
  final int upvotesCount;
  final bool isBest;
  final bool isAccepted;
  final DateTime createdAt;

  // Joined author metadata from user_profiles
  final String authorUsername;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final int authorReputation;

  Solution({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.upvotesCount,
    required this.isBest,
    required this.isAccepted,
    required this.createdAt,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    required this.authorReputation,
  });

  factory Solution.fromJson(Map<String, dynamic> json) {
    // Parse author nested map
    final authorMap = json['user_profiles'] as Map<String, dynamic>? ?? {};

    return Solution(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      upvotesCount: json['upvotes_count'] as int? ?? 0,
      isBest: json['is_best'] as bool? ?? false,
      isAccepted: json['is_accepted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      authorUsername: authorMap['username']?.toString() ?? 'anonymous',
      authorDisplayName: authorMap['display_name']?.toString() ?? 'Anonymous Student',
      authorAvatarUrl: authorMap['avatar_url']?.toString(),
      authorReputation: authorMap['reputation'] as int? ?? 0,
    );
  }

  Solution copyWith({
    String? id,
    String? postId,
    String? userId,
    String? body,
    int? upvotesCount,
    bool? isBest,
    bool? isAccepted,
    DateTime? createdAt,
    String? authorUsername,
    String? authorDisplayName,
    String? authorAvatarUrl,
    int? authorReputation,
  }) {
    return Solution(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      body: body ?? this.body,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      isBest: isBest ?? this.isBest,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorReputation: authorReputation ?? this.authorReputation,
    );
  }
}
