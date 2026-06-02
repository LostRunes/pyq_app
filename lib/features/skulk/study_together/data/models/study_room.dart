class StudyRoom {
  final String id;
  final String name;
  final String description;
  final String type;
  final String icon;
  final bool isVoiceEnabled;
  final bool isArchived;
  final DateTime lastMessageAt;
  final String? createdBy;

  StudyRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.isVoiceEnabled,
    required this.isArchived,
    required this.lastMessageAt,
    this.createdBy,
  });

  factory StudyRoom.fromJson(Map<String, dynamic> json) {
    return StudyRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: json['type'] as String,
      icon: json['icon'] as String? ?? '💬',
      isVoiceEnabled: json['is_voice_enabled'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      lastMessageAt: DateTime.parse(json['last_message_at'] ?? json['created_at']),
      createdBy: json['created_by'] as String?,
    );
  }
}
