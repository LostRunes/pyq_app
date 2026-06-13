import 'package:supabase_flutter/supabase_flutter.dart';

class StudyTogetherService {
  final _client = Supabase.instance.client;

  /// Fetches non-archived study rooms ordered by last_message_at desc
  Future<List<Map<String, dynamic>>> fetchActiveRooms() async {
    final res = await _client
        .from('study_rooms')
        .select()
        .eq('is_archived', false)
        .order('last_message_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetches messages for a given room (paginated, reverse list logic)
  /// ordered by created_at desc
  Future<List<Map<String, dynamic>>> fetchRoomMessages(
    String roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client
        .from('room_messages')
        .select()
        .eq('room_id', roomId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Sends a message, fetching current user profile to create a snapshot
  Future<Map<String, dynamic>> sendMessage(String roomId, String text) async {
    final user = _client.auth.currentUser;
    if (user == null)
      throw Exception('User must be logged in to send messages.');

    // Fetch user profile info for snapshotting
    final profileRes = await _client
        .from('user_profiles')
        .select('username, display_name, avatar_url')
        .eq('id', user.id)
        .maybeSingle();

    final profile = profileRes;

    final res = await _client
        .from('room_messages')
        .insert({
          'room_id': roomId,
          'user_id': user.id,
          'message': text,
          'sender_username': profile?['username'] ?? 'anonymous',
          'sender_display_name': profile?['display_name'] ?? 'User',
          'sender_avatar_url': profile?['avatar_url'],
        })
        .select()
        .single();

    return res;
  }
}
