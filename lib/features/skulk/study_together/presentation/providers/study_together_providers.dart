import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/providers.dart';
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

/// Direct Supabase helper to join by code or create a personal room
final roomOperationsProvider = Provider((ref) {
  final client = Supabase.instance.client;
  return RoomOperations(client);
});

class RoomOperations {
  final SupabaseClient _client;
  RoomOperations(this._client);

  /// Find a room by its 6-character room code stored in subject_id
  Future<StudyRoom?> findRoomByCode(String code) async {
    final res = await _client
        .from('study_rooms')
        .select()
        .eq('subject_id', code.toUpperCase().trim())
        .eq('is_archived', false)
        .maybeSingle();
    if (res == null) return null;
    return StudyRoom.fromJson(res);
  }

  /// Create a personal chat or voice room
  Future<StudyRoom> createPersonalRoom({
    required String name,
    required String description,
    required bool isVoiceEnabled,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to create rooms');

    // Generate random 6-character room code
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[(rand >> (i * 5)) % chars.length];
    }

    final res = await _client
        .from('study_rooms')
        .insert({
          'name': name,
          'description': description,
          'type': 'personal',
          'subject_id': code, // room code stored here
          'icon': isVoiceEnabled ? '🔊' : '💬',
          'is_voice_enabled': isVoiceEnabled,
          'created_by': user.id,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return StudyRoom.fromJson(res);
  }
}

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

/// Local Storage for added/joined rooms: key `skulk_joined_room_ids`
final joinedRoomIdsProvider = NotifierProvider<JoinedRoomsNotifier, List<String>>(
  JoinedRoomsNotifier.new,
);

class JoinedRoomsNotifier extends Notifier<List<String>> {
  static const String _key = 'skulk_joined_room_ids';

  @override
  List<String> build() {
    _loadJoinedRooms();
    return const [];
  }

  Future<void> _loadJoinedRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? [];
      state = list;
    } catch (_) {}
  }

  Future<void> addRoom(String roomId) async {
    if (state.contains(roomId)) return;
    state = [...state, roomId];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state);
    } catch (_) {}
  }

  Future<void> removeRoom(String roomId) async {
    state = state.where((id) => id != roomId).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state);
    } catch (_) {}
  }
}

/// Subject Rooms provider: filters subjects according to sem & branch, orders by core first, then elective.
/// Also includes any additional manually searched & added/joined rooms or personal rooms.
final subjectRoomsProvider = Provider.autoDispose<AsyncValue<List<StudyRoom>>>((ref) {
  final roomsAsync = ref.watch(studyRoomsProvider);
  final joinedIds = ref.watch(joinedRoomIdsProvider);
  
  // Try to read user's active branch and semester (first from selected branch/sem, fallback to splash session if possible)
  final activeBranchId = ref.watch(selectedBranchIdProvider);
  final activeSemester = ref.watch(selectedSemesterProvider);

  // Watch curriculum subjects
  final subjectsAsync = ref.watch(subjectsProvider((branchId: activeBranchId, semester: activeSemester)));

  // We can combine multiple AsyncValues using roomsAsync.when and subjectsAsync.when,
  // but let's return a single mapped AsyncValue using whenData on roomsAsync.
  return roomsAsync.when(
    loading: () => const AsyncValue<List<StudyRoom>>.loading(),
    error: (err, stack) => AsyncValue<List<StudyRoom>>.error(err, stack),
    data: (allRooms) {
      return subjectsAsync.when(
        loading: () => const AsyncValue<List<StudyRoom>>.loading(),
        error: (err, stack) => AsyncValue<List<StudyRoom>>.error(err, stack),
        data: (subjects) {
          // Map curriculum subject IDs and their type info
          final Map<String, int> subjectOrderMap = {}; // subjectId -> sorting weight
          final Map<String, String> subjectTypeMap = {}; // subjectId -> type ('core' / 'elective')
          
          for (final sub in subjects) {
            final typeLower = (sub.subjectType ?? '').toLowerCase();
            final isCore = typeLower.contains('core') || typeLower.isEmpty;
            final priority = sub.priority ?? 999;
            // Core subjects get weight 0..999, electives get 1000..1999
            final int weight = (isCore ? 0 : 1000) + priority;
            subjectOrderMap[sub.id] = weight;
            subjectTypeMap[sub.id] = isCore ? 'core' : 'elective';
          }

          final subjectIdsFromCurriculum = subjectOrderMap.keys.toSet();

          // Filter public rooms
          final List<StudyRoom> filtered = [];
          for (final room in allRooms) {
            final isSubject = room.type == 'subject';
            final isPersonal = room.type == 'personal';
            final isJoined = joinedIds.contains(room.id);
            
            if (isSubject) {
              final isFromCurriculum = room.subjectId != null && subjectIdsFromCurriculum.contains(room.subjectId);
              if (isFromCurriculum || isJoined) {
                filtered.add(room);
              }
            } else if (isPersonal && isJoined) {
              filtered.add(room);
            }
          }

          // Sort the filtered rooms:
          // 1. Personal rooms first (or you can sort them differently, let's keep them at the top or custom)
          // 2. Core subjects
          // 3. Elective subjects
          // 4. Any manually joined subjects that are not in the current curriculum
          filtered.sort((a, b) {
            // Sort by type: personal rooms first
            if (a.type == 'personal' && b.type != 'personal') return -1;
            if (b.type == 'personal' && a.type != 'personal') return 1;

            final aSubId = a.subjectId ?? '';
            final bSubId = b.subjectId ?? '';
            
            final aInCurriculum = subjectIdsFromCurriculum.contains(aSubId);
            final bInCurriculum = subjectIdsFromCurriculum.contains(bSubId);

            if (aInCurriculum && !bInCurriculum) return -1;
            if (!aInCurriculum && bInCurriculum) return 1;

            if (aInCurriculum && bInCurriculum) {
              final aWeight = subjectOrderMap[aSubId] ?? 9999;
              final bWeight = subjectOrderMap[bSubId] ?? 9999;
              return aWeight.compareTo(bWeight);
            }

            // Fallback: alphabetical by name
            return a.name.compareTo(b.name);
          });

          return AsyncValue<List<StudyRoom>>.data(filtered);
        },
      );
    },
  );
});

/// Community Spaces provider: study_rooms.type = 'community', 'general', or 'voice'
final communitySpacesProvider =
    Provider.autoDispose<AsyncValue<List<StudyRoom>>>((ref) {
      final roomsAsync = ref.watch(studyRoomsProvider);
      return roomsAsync.whenData(
        (rooms) {
          final filtered = rooms
              .where(
                (r) =>
                    r.type == 'community' ||
                    r.type == 'general' ||
                    r.type == 'voice',
              )
              .toList();

          filtered.sort((a, b) {
            int getWeight(StudyRoom room) {
              final name = room.name.toLowerCase();
              if (name.contains('general chat')) return 1;
              if (name.contains('placement')) return 2;
              if (name.contains('voice') || name.contains('lounge')) return 3;
              return 4;
            }

            final weightA = getWeight(a);
            final weightB = getWeight(b);
            if (weightA != weightB) {
              return weightA.compareTo(weightB);
            }
            return a.name.compareTo(b.name);
          });

          return filtered;
        },
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

class RoomTypingNotifier extends Notifier<List<String>> {
  RoomTypingNotifier(this.roomId);
  final String roomId;

  RealtimeChannel? _channel;
  final Map<String, Timer> _timers = {};

  @override
  List<String> build() {
    final supabase = Supabase.instance.client;
    
    _channel = supabase.channel('room-typing-$roomId')
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          final username = payload['username'] as String?;
          final isTyping = payload['is_typing'] as bool? ?? false;
          final userId = payload['user_id'] as String?;
          if (username == null || userId == null) return;
          
          final currentUserId = supabase.auth.currentUser?.id;
          if (userId == currentUserId) return; // ignore self

          if (isTyping) {
            _timers[userId]?.cancel();
            
            if (!state.contains(username)) {
              state = [...state, username];
            }
            
            _timers[userId] = Timer(const Duration(seconds: 4), () {
              state = state.where((u) => u != username).toList();
            });
          } else {
            _timers[userId]?.cancel();
            state = state.where((u) => u != username).toList();
          }
        },
      );
      
    _channel!.subscribe();

    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      if (_channel != null) {
        supabase.removeChannel(_channel!);
      }
    });

    return [];
  }

  Future<void> sendTyping(bool isTyping) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || _channel == null) return;

    String displayName = 'Someone';
    try {
      final res = await supabase
          .from('user_profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      if (res != null && res['display_name'] != null) {
        displayName = res['display_name'] as String;
      }
    } catch (_) {}

    await _channel!.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': user.id,
        'username': displayName,
        'is_typing': isTyping,
      },
    );
  }
}

final roomTypingProvider =
    NotifierProvider.family<RoomTypingNotifier, List<String>, String>(
      RoomTypingNotifier.new,
      isAutoDispose: true,
    );

final branchSubjectsMapProvider = FutureProvider<Map<String, List<({int semester, String branchId, String branchName, String code})>>>((ref) async {
  final client = ref.watch(supabaseServiceProvider).supabase;
  final res = await client
      .from('branch_subjects')
      .select('semester, branch_id, branches(name), subjects(code, id)');
  
  final Map<String, List<({int semester, String branchId, String branchName, String code})>> map = {};
  
  for (var row in res as List) {
    final subject = row['subjects'];
    if (subject == null) continue;
    final subjectId = subject['id'] as String;
    final code = subject['code'] as String? ?? '';
    final branch = row['branches'];
    final branchName = branch != null ? branch['name'] as String? ?? '' : '';
    final semester = row['semester'] as int? ?? 1;
    final branchIdVal = row['branch_id'] as String? ?? '';
    
    if (!map.containsKey(subjectId)) {
      map[subjectId] = [];
    }
    map[subjectId]!.add((
      semester: semester,
      branchId: branchIdVal,
      branchName: branchName,
      code: code,
    ));
  }
  return map;
});
