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
  final String? subjectId;
  final int maxParticipants;
  final int participantCount;
  final bool isActive;
  final DateTime? endedAt;
  final String? pinnedMessageId;

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
    this.subjectId,
    this.maxParticipants = 20,
    this.participantCount = 0,
    this.isActive = true,
    this.endedAt,
    this.pinnedMessageId,
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
      lastMessageAt: DateTime.parse(
        json['last_message_at'] ?? json['created_at'],
      ),
      createdBy: json['created_by'] as String?,
      subjectId: json['subject_id'] as String?,
      maxParticipants: json['max_participants'] as int? ?? 20,
      participantCount: json['participant_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      pinnedMessageId: json['pinned_message_id'] as String?,
    );
  }
}
