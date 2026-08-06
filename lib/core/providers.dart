import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/features/subjects/data/repositories/subjects_repository.dart';
import 'package:focus_fox/features/pyqs/data/repositories/pyq_repository.dart';
import '../services/ai_service.dart';
import '../services/drive_service.dart';
import '../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/prefs_provider.dart';

/// Primary DB client using the anon key.
/// Content tables (branches, subjects, topics, questions, gate_*, aptitude_*,
/// etc.) now have RLS enabled with public-read policies — the anon key is
/// sufficient for all read operations.
///
/// The service_role key is NO LONGER used in the Flutter app. Sensitive
/// operations (e.g. student lookup by roll number) go through the
/// `resolve-student` Supabase Edge Function instead.
final supabase1ClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_KEY'),  // anon key — RLS enforced
  );
});

final supabase2ClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    scopes: [
      'email',
      'profile',
    ],
  );
});

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(ref.watch(supabase1ClientProvider));
});

final pyqRepositoryProvider = Provider<PyqRepository>((ref) {
  return PyqRepository(ref.watch(supabase1ClientProvider));
});

final aiServiceProvider = Provider((ref) => AiService());
final driveServiceProvider = Provider((ref) => DriveService(ref.watch(googleSignInProvider)));

/// Fully signs the user out of both Google and Supabase.
/// Pass [ref] so that Riverpod provider state is invalidated immediately,
/// preventing the previous user's data from leaking into the next session.
Future<void> signOutCompletely({WidgetRef? ref}) async {
  try {
    await PushNotificationService.deleteDeviceToken();
  } catch (_) {}
  try {
    // 1. Clear Google's local cached session so the account picker always shows next time.
    // We read the shared instance so its local Dart state is cleared.
    // We do NOT use disconnect() by default here — disconnect() revokes the OAuth token server-side
    // and causes PlatformException on the next signIn() call. signOut() is enough.
    final googleSignIn = ref?.read(googleSignInProvider) ?? GoogleSignIn(
      serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      scopes: [
        'email',
        'profile',
      ],
    );
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


