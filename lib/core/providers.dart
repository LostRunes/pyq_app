import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:focus_fox/features/subjects/data/repositories/subjects_repository.dart';
import 'package:focus_fox/features/pyqs/data/repositories/pyq_repository.dart';
import '../services/ai_service.dart';
import '../services/drive_service.dart';
import '../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/prefs_provider.dart';

/// Primary DB client using the service role key.
/// This bypasses RLS — necessary because the user's auth session lives on
/// the secondary DB (Supabase.instance.client), so auth.uid() is always
/// null on this client and RLS policies would silently block all writes.
final supabase1ClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_SERVICE']!,
  );
});

final supabase2ClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(ref.watch(supabase1ClientProvider));
});

final pyqRepositoryProvider = Provider<PyqRepository>((ref) {
  return PyqRepository(ref.watch(supabase1ClientProvider));
});

final aiServiceProvider = Provider((ref) => AiService());
final driveServiceProvider = Provider((ref) => DriveService());

/// Fully signs the user out of both Google and Supabase.
/// Pass [ref] so that Riverpod provider state is invalidated immediately,
/// preventing the previous user's data from leaking into the next session.
Future<void> signOutCompletely({WidgetRef? ref}) async {
  try {
    await PushNotificationService.deleteDeviceToken();
  } catch (_) {}
  try {
    // 1. Clear Google's local cached session so the account picker always shows next time.
    // We use signOut() (not disconnect()) — disconnect() revokes the OAuth token server-side
    // and causes PlatformException on the next signIn() call. signOut() is enough because
    // we already removed signInSilently() from the sign-in flow, which was the root cause
    // of the auto-login skipping the account picker.
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  } catch (_) {
    // Ignore Google sign-out errors (user may not have used Google sign-in)
  }
  try {
    // 2. Sign out from Supabase (invalidates session server-side)
    await Supabase.instance.client.auth.signOut();
  } catch (_) {
    // Ignore Supabase sign-out errors
  }
  try {
    // 3. Sign out from Supabase 1
    final supabase1 = ref?.read(supabase1ClientProvider);
    if (supabase1 != null) {
      await supabase1.auth.signOut();
    }
  } catch (_) {}
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_branch_id');
    await prefs.remove('selected_semester');
  } catch (_) {
    // Ignore SharedPreferences errors
  }

  // Invalidate Riverpod providers that hold per-user state so that
  // a subsequent login starts with clean data.
  if (ref != null) {
    try {
      ref.invalidate(selectedBranchIdProvider);
      ref.invalidate(selectedSemesterProvider);
      ref.invalidate(mainNavigationIndexProvider);
      // userProfileProvider is autoDispose — it will self-invalidate
      // beeEnabledProvider and beeTapCountProvider are shared preferences
      // backed so they'll re-read correctly on next launch
    } catch (_) {}
  }
}

class MainNavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final mainNavigationIndexProvider =
    NotifierProvider<MainNavigationIndexNotifier, int>(
  MainNavigationIndexNotifier.new,
);


