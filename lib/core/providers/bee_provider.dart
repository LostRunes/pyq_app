import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers/user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Bee tap counter (persisted) ──────────────────────────────────────────────

class BeeTapCountNotifier extends Notifier<int> {
  static const _key = 'bee_tap_count';

  @override
  int build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final localCount = prefs.getInt(_key) ?? 0;

    // Sync initially if user is already logged in
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Future.microtask(() => _syncWithSupabase(user, localCount));
    }

      // Listen for future auth state changes
    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      final prevUser = previous?.value;
      final newUser = next.value;

      if (newUser != null) {
        // If the user identity changed (account switch or fresh login after logout),
        // reset the local count to 0 first so we don't push stale data into the new
        // user's record. The sync will then pull the correct remote count.
        if (prevUser?.id != newUser.id) {
          state = 0;
          final prefs = ref.read(sharedPrefsProvider);
          prefs.setInt(_key, 0);
        }
        _syncWithSupabase(newUser, state);
      }
    });

    return localCount;
  }

  Future<void> increment() async {
    state = state + 1;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt(_key, state);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('user_bee_kills').upsert({
          'user_id': user.id,
          'kills': state,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        print('Failed to upsert bee kills on increment: $e');
      }
    }
  }

  Future<void> _syncWithSupabase(User user, int localCount) async {
    try {
      final response = await Supabase.instance.client
          .from('user_bee_kills')
          .select('kills')
          .eq('user_id', user.id)
          .maybeSingle();

      int remoteCount = 0;
      if (response != null && response['kills'] != null) {
        remoteCount = response['kills'] as int;
      }

      if (localCount > remoteCount) {
        // Sync local count to database
        await Supabase.instance.client.from('user_bee_kills').upsert({
          'user_id': user.id,
          'kills': localCount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else if (remoteCount > localCount) {
        // Sync database count to local
        state = remoteCount;
        final prefs = ref.read(sharedPrefsProvider);
        await prefs.setInt(_key, remoteCount);
      }
    } catch (e) {
      print('Failed to sync bee kills with Supabase: $e');
    }
  }
}

final beeTapCountProvider = NotifierProvider<BeeTapCountNotifier, int>(
  BeeTapCountNotifier.new,
);

// ── Bee visibility toggle (persisted) ───────────────────────────────────────

class BeeEnabledNotifier extends Notifier<bool> {
  static const _key = 'bee_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_key, state);
  }
}

final beeEnabledProvider = NotifierProvider<BeeEnabledNotifier, bool>(
  BeeEnabledNotifier.new,
);
