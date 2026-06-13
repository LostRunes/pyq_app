import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/study_room.dart';
import '../../data/models/room_message.dart';
import '../../data/services/study_together_service.dart';
import '../../data/repositories/study_together_repository.dart';

/// Database service provider
final studyTogetherServiceProvider = Provider<StudyTogetherService>((ref) {
  return StudyTogetherService();
});

/// Repository provider
final studyTogetherRepositoryProvider = Provider<StudyTogetherRepository>((
  ref,
) {
  final service = ref.watch(studyTogetherServiceProvider);
  return StudyTogetherRepository(service: service);
});

/// Fetches active study rooms sorted by last_message_at desc
final studyRoomsProvider = FutureProvider.autoDispose<List<StudyRoom>>((
  ref,
) async {
  final repo = ref.watch(studyTogetherRepositoryProvider);
  return repo.getActiveRooms();
});

/// Active Lobbies provider: study_rooms.type = 'lobby'
final activeLobbiesProvider = Provider.autoDispose<AsyncValue<List<StudyRoom>>>(
  (ref) {
    final roomsAsync = ref.watch(studyRoomsProvider);
    return roomsAsync.whenData(
      (rooms) => rooms.where((r) => r.type == 'lobby').toList(),
    );
  },
);

/// Subject Rooms provider: study_rooms.type = 'subject'
final subjectRoomsProvider = Provider.autoDispose<AsyncValue<List<StudyRoom>>>((
  ref,
) {
  final roomsAsync = ref.watch(studyRoomsProvider);
  return roomsAsync.whenData(
    (rooms) => rooms.where((r) => r.type == 'subject').toList(),
  );
});

/// Community Spaces provider: study_rooms.type = 'community', 'general', or 'voice'
final communitySpacesProvider =
    Provider.autoDispose<AsyncValue<List<StudyRoom>>>((ref) {
      final roomsAsync = ref.watch(studyRoomsProvider);
      return roomsAsync.whenData(
        (rooms) => rooms
            .where(
              (r) =>
                  r.type == 'community' ||
                  r.type == 'general' ||
                  r.type == 'voice',
            )
            .toList(),
      );
    });

/// Chat room state management: manages paginated room history and receives real-time Postgres insertions
class RoomChatNotifier extends Notifier<List<RoomMessage>> {
  RoomChatNotifier(this.roomId);
  final String roomId;

  static const int _pageSize = 50;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  RealtimeChannel? _realtimeChannel;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  List<RoomMessage> build() {
    // Load initial page
    _loadInitialMessages();

    // Subscribe to real-time Postgres insertions on room_messages for this room
    final supabase = Supabase.instance.client;
    _realtimeChannel = supabase
        .channel('room-messages-changes-$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'room_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final newMsgJson = payload.newRecord;
            // Skip if soft-deleted
            if (newMsgJson['deleted_at'] != null) return;
            final newMsg = RoomMessage.fromJson(newMsgJson);

            // Prevent duplicate appending
            final exists = state.any((m) => m.id == newMsg.id);
            if (!exists) {
              state = [newMsg, ...state];
            }
          },
        );

    _realtimeChannel!.subscribe();

    ref.onDispose(() {
      if (_realtimeChannel != null) {
        supabase.removeChannel(_realtimeChannel!);
      }
    });

    return [];
  }

  Future<void> _loadInitialMessages() async {
    final repo = ref.read(studyTogetherRepositoryProvider);
    try {
      final list = await repo.getRoomMessages(
        roomId,
        limit: _pageSize,
        offset: 0,
      );
      state = list;
      if (list.length < _pageSize) {
        _hasMore = false;
      }
    } catch (_) {}
  }

  /// Load older messages (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _offset += _pageSize;

    final repo = ref.read(studyTogetherRepositoryProvider);
    try {
      final nextPage = await repo.getRoomMessages(
        roomId,
        limit: _pageSize,
        offset: _offset,
      );
      if (nextPage.length < _pageSize) {
        _hasMore = false;
      }
      state = [...state, ...nextPage];
    } catch (_) {
      _offset -= _pageSize; // Revert offset if fails
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Send message helper
  Future<void> sendMessage(String text) async {
    final repo = ref.read(studyTogetherRepositoryProvider);
    try {
      // Opt-in DB insert
      final sentMsg = await repo.sendMessage(roomId, text);
      // Ensure local state receives it immediately in case of delay
      final exists = state.any((m) => m.id == sentMsg.id);
      if (!exists) {
        state = [sentMsg, ...state];
      }
    } catch (_) {
      rethrow;
    }
  }
}

final roomChatProvider =
    NotifierProvider.family<RoomChatNotifier, List<RoomMessage>, String>(
      RoomChatNotifier.new,
      isAutoDispose: true,
    );

/// Room Presence state management to track online user counts dynamically
class RoomPresenceNotifier extends Notifier<int> {
  RoomPresenceNotifier(this.roomId);
  final String roomId;

  RealtimeChannel? _presenceChannel;

  @override
  int build() {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    _presenceChannel = supabase.channel('presence-room-$roomId');

    _presenceChannel!.onPresenceSync((payload) {
      final presenceState = _presenceChannel!.presenceState();

      // Extract unique user IDs present in the state
      final uniqueUsers = <String>{};
      for (final presence in presenceState) {
        for (final p in presence.presences) {
          final uid = p.payload['user_id'] as String?;
          if (uid != null) {
            uniqueUsers.add(uid);
          }
        }
      }

      // Update the reactive state with the number of unique online users
      state = uniqueUsers.length;
    });

    _presenceChannel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed &&
          currentUserId != null) {
        await _presenceChannel!.track({'user_id': currentUserId});
      }
    });

    ref.onDispose(() {
      if (_presenceChannel != null) {
        supabase.removeChannel(_presenceChannel!);
      }
    });

    return 1; // Default to 1 (current user)
  }
}

final roomPresenceProvider =
    NotifierProvider.family<RoomPresenceNotifier, int, String>(
      RoomPresenceNotifier.new,
      isAutoDispose: true,
    );
