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
    if (user == null) {
      throw Exception('User must be logged in to send messages.');
    }

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

    // Insert mention notifications if any users are tagged in the text
    try {
      final cleanedText = text
          .replaceAll(RegExp(r'^\[reply:[^\]]*\]'), '')
          .replaceAll(RegExp(r'\[image:[^\]]*\]'), '')
          .trim();

      final mentionRegex = RegExp(r'@([a-zA-Z0-9_]+)');
      final matches = mentionRegex.allMatches(cleanedText);
      final usernames = matches.map((m) => m.group(1)!).toSet().toList();

      if (usernames.isNotEmpty) {
        final usersRes = await _client
            .from('user_profiles')
            .select('id, username')
            .inFilter('username', usernames);

        final taggedUsers = List<Map<String, dynamic>>.from(usersRes);
        final senderName = profile?['display_name'] ?? profile?['username'] ?? 'User';

        final roomRes = await _client
            .from('study_rooms')
            .select('name')
            .eq('id', roomId)
            .maybeSingle();
        final roomName = roomRes?['name'] ?? 'Study Room';

        for (final taggedUser in taggedUsers) {
          final taggedUserId = taggedUser['id'] as String?;
          if (taggedUserId != null && taggedUserId != user.id) {
            await _client.from('notifications').insert({
              'user_id': taggedUserId,
              'type': 'mention',
              'message': '$senderName tagged you in "$roomName"',
              'post_id': roomId,
              'actor_id': user.id,
              'actor_username': profile?['username'],
              'actor_display_name': profile?['display_name'],
            });
          }
        }
      }
    } catch (_) {
      // Fail silently to ensure message sending doesn't break if notification table insert fails
    }

    return res;
  }

  /// Edits a message
  Future<Map<String, dynamic>> editMessage(String messageId, String newText) async {
    final res = await _client
        .from('room_messages')
        .update({
          'message': newText,
          'edited_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId)
        .select()
        .single();
    return res;
  }

  /// Soft deletes a message by setting deleted_at
  Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    final res = await _client
        .from('room_messages')
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId)
        .select()
        .single();
    return res;
  }
}
