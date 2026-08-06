import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/features/subjects/data/models/branch.dart';
import '../../../../services/analytics_service.dart';

class RedirectResult {
  final String routeName;
  final Map<String, dynamic>? arguments;

  RedirectResult(this.routeName, [this.arguments]);
}

class AuthRepository {
  final SupabaseClient _supabase1;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    scopes: ['email', 'profile'],
  );

  AuthRepository(this._supabase1);

  Future<void> signInWithGoogle() async {
    try {
      // Do NOT call signInSilently() here — it bypasses the account picker and
      // auto-selects the previously cached account without user confirmation.
      // We always want the explicit account picker after a logout.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User dismissed the picker
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google Sign In failed: could not retrieve ID token. '
          'Check that GOOGLE_WEB_CLIENT_ID in .env matches your Supabase Google provider.',
        );
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('deadlock') || errStr.contains('main thread')) {
        try {
          await _googleSignIn.disconnect();
        } catch (_) {}
        throw Exception(
          'Sign-in initializing, please tap "Continue with Google" again.',
        );
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>?> handlePostLogin(User user) async {
    unawaited(AnalyticsService.setUser(user.id));
    unawaited(AnalyticsService.logLogin());

    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    // A Supabase trigger auto-creates the user_profiles row on signup,
    // with a default username like 'user_xxxxxxxx' and null avatar_url.
    // Treat it as a new profile if username/avatar is missing or default.
    if (profile == null) return null;
    final username = profile['username'] as String?;
    final avatarUrl = profile['avatar_url'] as String?;
    final isNewProfile =
        username == null ||
        username.trim().isEmpty ||
        avatarUrl == null ||
        avatarUrl.trim().isEmpty ||
        (username.startsWith('user_') && username.length == 13);

    if (isNewProfile) return null;

    return profile;
  }

  Future<Map<String, dynamic>?> _getStudentByRollNo(String rollNo) async {
    try {
      final res = await _supabase1
          .from('students')
          .select()
          .eq('roll_no', rollNo)
          .maybeSingle();
      return res;
    } catch (e) {
      return null;
    }
  }

  Future<String> _getBranchIdFromSection(String section) async {
    try {
      final res = await _supabase1.from('branches').select();
      final branches = (res as List).map((e) => Branch.fromJson(e)).toList();
      if (branches.isEmpty) return '';

      final secUpper = section.toUpperCase();

      for (var branch in branches) {
        final nameUpper = branch.name.toUpperCase();
        if (secUpper.contains(nameUpper) || nameUpper.contains(secUpper)) {
          return branch.id;
        }
      }

      if (secUpper.startsWith('B') && RegExp(r'^B\d+$').hasMatch(secUpper)) {
        final cseBranch = branches.firstWhere(
          (b) => b.name.toUpperCase().contains('CS'),
          orElse: () => branches.first,
        );
        return cseBranch.id;
      }

      return branches.first.id;
    } catch (e) {
      return '';
    }
  }

  Future<RedirectResult> getRedirectResult(String email) async {
    final kiitRegex = RegExp(r'^(\d+)@kiit\.ac\.in$', caseSensitive: false);
    final match = kiitRegex.firstMatch(email);

    if (match != null) {
      final rollNo = match.group(1)!;
      final student = await _getStudentByRollNo(rollNo);

      if (student != null) {
        final batch = student['batch']?.toString() ?? '';
        final section = student['section']?.toString() ?? '';

        final branchId = await _getBranchIdFromSection(section);
        final semester = _getSemesterFromBatch(batch);

        return RedirectResult('/main_navigation', {
          'branchId': branchId,
          'semester': semester,
        });
      }
    }

    return RedirectResult('/selection');
  }

  int _getSemesterFromBatch(String batch) {
    final match = RegExp(r'\d+').firstMatch(batch);
    if (match == null) {
      debugPrint(
        'Warning: Could not parse batch number from "$batch". Defaulting to semester 1.',
      );
      return 1;
    }

    int batchNum = int.parse(match.group(0)!);

    // If the batch number is a calendar year (e.g. 2023), convert it to a relative year of study (1-4).
    // Assuming the year represents the admission year.
    if (batchNum > 2000) {
      final currentYear = DateTime.now().year;
      final admissionYear = batchNum;
      final diff = currentYear - admissionYear;
      batchNum = (diff + 1).clamp(1, 4);
      debugPrint(
        'Resolved calendar year batch "$batch" (admission year: $admissionYear) to year of study: $batchNum.',
      );
    }

    final month = DateTime.now().month;
    final isEvenSemester = month >= 1 && month <= 6;

    if (isEvenSemester) {
      return (2 * batchNum - 2).clamp(1, 8);
    } else {
      return (2 * batchNum - 1).clamp(1, 8);
    }
  }

  Future<bool> checkUsernameUnique(String username) async {
    final res = await Supabase.instance.client
        .from('user_profiles')
        .select('id')
        .eq('username', username.toLowerCase())
        .maybeSingle();
    return res == null;
  }

  Future<void> submitUsername({
    required String userId,
    required String username,
    required String? displayName,
    required String avatarUrl,
  }) async {
    await Supabase.instance.client.from('user_profiles').upsert({
      'id': userId,
      'username': username.toLowerCase(),
      'display_name': displayName,
      'avatar_url': avatarUrl,
    });
  }

  String generateCoolUsername() {
    final adjectives = [
      'smart',
      'study',
      'focus',
      'epic',
      'cyber',
      'nerdy',
      'sleepy',
      'shadow',
      'swift',
      'clever',
      'cosmic',
      'pixel',
      'bright',
      'super',
      'quick',
      'bold',
      'alpha',
      'omega',
      'zen',
      'active',
      'prime',
      'stellar',
      'happy',
      'coding',
    ];
    final nouns = [
      'fox',
      'panda',
      'pikachu',
      'cat',
      'octopus',
      'owl',
      'bear',
      'raccoon',
      'shark',
      'dragon',
      'scholar',
      'coder',
      'genius',
      'learner',
      'champion',
      'wizard',
    ];
    final rand = Random();
    final adj = adjectives[rand.nextInt(adjectives.length)];
    final noun = nouns[rand.nextInt(nouns.length)];
    final num = rand.nextInt(900) + 100; // 3 digit number: 100-999

    return '${adj}_${noun}_$num';
  }
}
