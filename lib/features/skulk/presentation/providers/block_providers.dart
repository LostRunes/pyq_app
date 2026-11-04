import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// IDs of users the signed-in user has blocked (table `user_blocks`).
/// Content from these users is hidden from the Skulk feed, answers, comments
/// and study-room chat. Reloads whenever the signed-in user changes.
class BlockedUsersNotifier extends Notifier<Set<String>> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Set<String> build() {
    final sub = _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.userUpdated) {
        unawaited(_load());
      }
    });
    ref.onDispose(sub.cancel);
    unawaited(_load());
    return const <String>{};
  }

  Future<void> _load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      state = const <String>{};
      return;
    }
    try {
      final rows = await _client
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', userId);
      state = {for (final r in rows as List) r['blocked_id'].toString()};
    } catch (e) {
      debugPrint('[BlockedUsers] Failed to load blocks: $e');
    }
  }

  Future<void> block(String blockedUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    if (blockedUserId == userId) throw Exception("You can't block yourself");

    final previous = state;
    state = {...state, blockedUserId};
    try {
      await _client.from('user_blocks').upsert({
        'blocker_id': userId,
        'blocked_id': blockedUserId,
      }, ignoreDuplicates: true);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> unblock(String blockedUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final previous = state;
    state = {...state}..remove(blockedUserId);
    try {
      await _client
          .from('user_blocks')
          .delete()
          .eq('blocker_id', userId)
          .eq('blocked_id', blockedUserId);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}

final blockedUserIdsProvider =
    NotifierProvider<BlockedUsersNotifier, Set<String>>(
      BlockedUsersNotifier.new,
    );

/// A user the signed-in user has blocked, with profile details for display.
class BlockedUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const BlockedUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });
}

/// Blocked users with names, for the Settings "Blocked users" list.
final blockedUsersListProvider = FutureProvider.autoDispose<List<BlockedUser>>((
  ref,
) async {
  ref.watch(blockedUserIdsProvider);
  final rows = await Supabase.instance.client.rpc('my_blocked_users');
  return [
    for (final r in rows as List)
      BlockedUser(
        id: r['id'].toString(),
        username: (r['username'] as String?) ?? 'user',
        displayName: (r['display_name'] as String?) ?? 'Skulk user',
        avatarUrl: r['avatar_url'] as String?,
      ),
  ];
});

/// Asks for confirmation, then blocks [userId]. Returns true if blocked.
Future<bool> confirmAndBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String displayName,
}) async {
  final name = displayName.trim().isEmpty ? 'this user' : displayName.trim();
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Block $name?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Text(
        "You won't see their doubts, answers, comments or study-room messages. "
        "They won't be notified. You can unblock them anytime from Settings.",
        style: GoogleFonts.outfit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            'Block',
            style: GoogleFonts.outfit(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
  if (confirm != true) return false;

  try {
    await ref.read(blockedUserIdsProvider.notifier).block(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name has been blocked.')),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not block $name: $e')),
      );
    }
    return false;
  }
}

/// Popup-menu entry used next to "Report" in Skulk menus.
PopupMenuItem<String> blockUserMenuItem() {
  return PopupMenuItem(
    value: 'block',
    child: Row(
      children: [
        const Icon(Icons.block_rounded, size: 16, color: Colors.redAccent),
        const SizedBox(width: 8),
        Text(
          'Block User',
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.redAccent),
        ),
      ],
    ),
  );
}
