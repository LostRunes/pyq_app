import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';

// ── Bee tap counter (persisted) ──────────────────────────────────────────────

class BeeTapCountNotifier extends Notifier<int> {
  static const _key = 'bee_tap_count';

  @override
  int build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getInt(_key) ?? 0;
  }

  Future<void> increment() async {
    state = state + 1;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt(_key, state);
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
