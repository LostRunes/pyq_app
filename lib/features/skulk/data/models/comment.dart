class Comment {
  final String id;
  final String userId;
  final String postId;
  final String? answerId;
  final String? parentCommentId;
  final String body;
  final DateTime createdAt;

  // Joined author metadata from user_profiles
  final String authorUsername;
  final String authorDisplayName;
  final String? authorAvatarUrl;

  Comment({
    required this.id,
    required this.userId,
    required this.postId,
    this.answerId,
    this.parentCommentId,
    required this.body,
    required this.createdAt,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorAvatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Parse author nested map
    final authorMap = json['user_profiles'] as Map<String, dynamic>? ?? {};

    return Comment(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      answerId: json['answer_id']?.toString(),
      parentCommentId: json['parent_comment_id']?.toString(),
      body: json['body']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      authorUsername: authorMap['username']?.toString() ?? 'anonymous',
      authorDisplayName:
          authorMap['display_name']?.toString() ?? 'Anonymous Student',
      authorAvatarUrl: authorMap['avatar_url']?.toString(),
    );
  }

  Comment copyWith({
    String? id,
    String? userId,
    String? postId,
    String? answerId,
    String? parentCommentId,
    String? body,
    DateTime? createdAt,
    String? authorUsername,
    String? authorDisplayName,
    String? authorAvatarUrl,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      answerId: answerId ?? this.answerId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    );
  }
}
