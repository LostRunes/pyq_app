import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LiveKitService {
  Room? _room;
  Room? get room => _room;

  final _supabase = Supabase.instance.client;

  /// Fetches a token from our Supabase Edge Function
  Future<Map<String, dynamic>> fetchToken(String roomId, String identity, String name) async {
    try {
      final res = await _supabase.functions.invoke(
        'livekit-token',
        body: {
          'room_id': roomId,
          'identity': identity,
          'name': name,
        },
      );
      
      if (res.status != 200) {
        throw Exception('Failed to invoke edge function: ${res.data}');
      }
      
      final data = res.data as Map<String, dynamic>;
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching LiveKit token: $e');
      }
      rethrow;
    }
  }

  /// Connects to a LiveKit room using the given WebSocket URL and JWT Token
  Future<Room> connect(String wsUrl, String token) async {
    try {
      await disconnect();

      final room = Room();
      _room = room;

      await room.connect(
        wsUrl,
        token,
      );

      return room;
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting to LiveKit room: $e');
      }
      rethrow;
    }
  }

  /// Disconnects from the current room
  Future<void> disconnect() async {
    if (_room != null) {
      await _room!.disconnect();
      _room = null;
    }
  }

  /// Enables or disables the local microphone track
  Future<void> setMicEnabled(bool enabled) async {
    final localPart = _room?.localParticipant;
    if (localPart != null) {
      await localPart.setMicrophoneEnabled(enabled);
    }
  }
}
