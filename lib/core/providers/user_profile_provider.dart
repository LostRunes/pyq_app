import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return await Supabase.instance.client
      .from('user_profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
});
