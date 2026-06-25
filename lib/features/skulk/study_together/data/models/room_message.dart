class RoomMessage {
  final String id;
  final String roomId;
  final String userId;
  final String message;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  // Snapshot fields to avoid active profile joins
  final String? senderUsername;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final Map<String, dynamic> reactions;

  RoomMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.message,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.senderUsername,
    this.senderDisplayName,
    this.senderAvatarUrl,
    this.reactions = const {},
  });

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    return RoomMessage(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      senderUsername: json['sender_username'] as String?,
      senderDisplayName: json['sender_display_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      reactions: json['reactions'] as Map<String, dynamic>? ?? const {},
    );
  }
}
