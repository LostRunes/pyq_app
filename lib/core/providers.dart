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

final supabase1ClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_KEY']!,
  );
});

final supabase2ClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(
    dotenv.env['SUPABASE_2_URL']!,
    dotenv.env['SUPABASE_2_KEY']!,
  );
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
/// Call this from any logout button. After this, the next Google sign-in
/// will always show the account picker (no silent re-auth).
Future<void> signOutCompletely() async {
  try {
    await PushNotificationService.deleteDeviceToken();
  } catch (_) {}
  try {
    // 1. Revoke Google token so account picker shows next time
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_branch_id');
    await prefs.remove('selected_semester');
  } catch (_) {
    // Ignore SharedPreferences errors
  }
}
