import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks the currently authenticated Supabase user.
/// Rebuilds whenever the auth state changes (login / logout / token refresh).
final _authUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

/// Fetches the user profile for the currently logged-in user.
/// Auto-disposes and re-fetches whenever the auth user changes,
/// so the avatar and display name always match the active session.
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  // Re-runs whenever the auth user changes (login/logout/switch account)
  final user = ref.watch(_authUserProvider).value;
  if (user == null) return null;
  return await Supabase.instance.client
      .from('user_profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
});
