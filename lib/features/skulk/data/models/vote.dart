class Vote {
  final String id;
  final String userId;
  final String? postId;
  final String? answerId;
  final int value; // 1 for upvote
  final DateTime createdAt;

  Vote({
    required this.id,
    required this.userId,
    this.postId,
    this.answerId,
    required this.value,
    required this.createdAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      postId: json['post_id']?.toString(),
      answerId: json['answer_id']?.toString(),
      value: json['value'] as int? ?? 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
