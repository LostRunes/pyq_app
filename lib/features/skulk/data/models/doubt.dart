class Doubt {
  final String id;
  final String userId;
  final String subjectId;
  final String title;
  final String body;
  final List<String> tags;
  final int upvotesCount;
  final int answersCount;
  final int commentsCount;
  final int viewsCount;
  final bool isSolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imageUrls;

  // Joined author metadata from user_profiles
  final String authorUsername;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final int authorReputation;

  // Locally resolved curriculum metadata from Supabase 1
  final String subjectName;

  Doubt({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.title,
    required this.body,
    required this.tags,
    required this.upvotesCount,
    required this.answersCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.isSolved,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    required this.authorReputation,
    this.subjectName = '',
  });

  factory Doubt.fromJson(Map<String, dynamic> json, {String subjectName = ''}) {
    // Parse author nested map
    final authorMap = json['user_profiles'] as Map<String, dynamic>? ?? {};

    // Parse tags list
    final rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = List<String>.from(rawTags.map((e) => e.toString()));
    } else if (rawTags is String) {
      // Fallback in case tags are returned as comma-separated string
      parsedTags = rawTags.isEmpty
          ? []
          : rawTags.split(',').map((e) => e.trim()).toList();
    }

    // Parse image URLs list
    final rawImageUrls = json['image_urls'];
    List<String> parsedImageUrls = [];
    if (rawImageUrls is List) {
      parsedImageUrls = List<String>.from(
        rawImageUrls.map((e) => e.toString()),
      );
    }

    return Doubt(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      tags: parsedTags,
      upvotesCount: json['upvotes_count'] as int? ?? 0,
      answersCount: json['answers_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      isSolved: json['is_solved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      imageUrls: parsedImageUrls,
      authorUsername: authorMap['username']?.toString() ?? 'anonymous',
      authorDisplayName:
          authorMap['display_name']?.toString() ?? 'Anonymous Student',
      authorAvatarUrl: authorMap['avatar_url']?.toString(),
      authorReputation: authorMap['reputation'] as int? ?? 0,
      subjectName: subjectName,
    );
  }

  Doubt copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? body,
    List<String>? tags,
    int? upvotesCount,
    int? answersCount,
    int? commentsCount,
    int? viewsCount,
    bool? isSolved,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    String? authorUsername,
    String? authorDisplayName,
    String? authorAvatarUrl,
    int? authorReputation,
    String? subjectName,
  }) {
    return Doubt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      answersCount: answersCount ?? this.answersCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isSolved: isSolved ?? this.isSolved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      authorUsername: authorUsername ?? this.authorUsername,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorReputation: authorReputation ?? this.authorReputation,
      subjectName: subjectName ?? this.subjectName,
    );
  }
}
