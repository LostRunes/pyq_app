import 'study_room.dart';

class ActiveLobby extends StudyRoom {
  ActiveLobby({
    required super.id,
    required super.name,
    required super.description,
    required super.type,
    required super.icon,
    required super.isVoiceEnabled,
    required super.isArchived,
    required super.lastMessageAt,
    super.createdBy,
  });

  factory ActiveLobby.fromStudyRoom(StudyRoom room) {
    return ActiveLobby(
      id: room.id,
      name: room.name,
      description: room.description,
      type: room.type,
      icon: room.icon,
      isVoiceEnabled: room.isVoiceEnabled,
      isArchived: room.isArchived,
      lastMessageAt: room.lastMessageAt,
      createdBy: room.createdBy,
    );
  }
}
