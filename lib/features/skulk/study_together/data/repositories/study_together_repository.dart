import '../models/study_room.dart';
import '../models/room_message.dart';
import '../services/study_together_service.dart';

class StudyTogetherRepository {
  final StudyTogetherService _service;

  StudyTogetherRepository({required StudyTogetherService service})
    : _service = service;

  /// Fetches non-archived study rooms ordered by active state
  Future<List<StudyRoom>> getActiveRooms() async {
    final rawRooms = await _service.fetchActiveRooms();
    return rawRooms.map((json) => StudyRoom.fromJson(json)).toList();
  }

  /// Fetches room messages, paginated
  Future<List<RoomMessage>> getRoomMessages(
    String roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rawMessages = await _service.fetchRoomMessages(
      roomId,
      limit: limit,
      offset: offset,
    );
    return rawMessages.map((json) => RoomMessage.fromJson(json)).toList();
  }

  /// Sends a text message to a room
  Future<RoomMessage> sendMessage(String roomId, String messageText) async {
    final rawMessage = await _service.sendMessage(roomId, messageText);
    return RoomMessage.fromJson(rawMessage);
  }
}
