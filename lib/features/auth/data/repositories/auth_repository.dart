import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:focus_fox/core/config/env.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    clientId: kIsWeb ? Env.googleWebClientIdOrNull : null,
    serverClientId: !kIsWeb ? Env.googleWebClientIdOrNull : null,
    scopes: [
      'email',
      'profile',
    ],
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

      // 1. Sign in to Supabase 2 (Main auth instance)
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      // 2. Sign in to Supabase 1 (Content & customizations instance)
      try {
        await _supabase1.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
        );
      } catch (e) {
        debugPrint('[AuthRepository] Supabase 1 client sign-in failed: $e');
      }
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

  /// Sign in with Apple (required on iOS alongside Google, App Store 4.8).
  /// Returns the user's name from Apple, which Apple only shares on the very
  /// first sign-in; null if the user cancelled or no name was shared.
  Future<String?> signInWithApple() async {
    // Apple embeds sha256(rawNonce) in the ID token; Supabase verifies it
    // against the raw nonce, so a stolen token can't be replayed.
    final rawNonce = _generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Sign in with Apple failed: no identity token returned.');
    }

    // 1. Main auth instance
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // 2. Content & customizations instance
    try {
      await _supabase1.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } catch (e) {
      debugPrint('[AuthRepository] Supabase 1 client Apple sign-in failed: $e');
    }

    final fullName = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    return fullName.isEmpty ? null : fullName;
  }

  String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Permanently deletes the signed-in user's account (App Store 5.1.1(v)).
  /// Throws if the main account could not be deleted; the caller should then
  /// sign the user out locally with signOutCompletely().
  Future<void> deleteAccount() async {
    final mainUserId = Supabase.instance.client.auth.currentUser?.id;
    if (mainUserId == null) throw Exception('Not signed in');

    // 1. Main project: profile, Skulk content, rooms, progress, analytics and
    //    the login itself (database function delete_my_account). If this
    //    fails nothing is deleted, so the error is shown to the user.
    await Supabase.instance.client.rpc('delete_my_account');

    // 2. Content project: its own login for the same person.
    try {
      if (_supabase1.auth.currentSession == null) {
        await recoverSupabase1Session();
      }
      if (_supabase1.auth.currentSession != null) {
        await _supabase1.rpc('delete_my_account');
      }
    } catch (e) {
      debugPrint('[AuthRepository] Content project account deletion failed: $e');
    }
    try {
      await _supabase1.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}

    // 3. Subject customizations are keyed by the main user id. With the
    //    content session cleared, this client is back on its own key.
    try {
      await _supabase1
          .from('user_subject_customizations')
          .delete()
          .eq('user_id', mainUserId);
    } catch (e) {
      debugPrint('[AuthRepository] Deleting subject customizations failed: $e');
    }

    // 4. Revoke the app's Google access (no-op for Apple sign-in users).
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }

  Future<void> recoverSupabase1Session() async {
    try {
      if (_supabase1.auth.currentSession != null) return;

      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        if (googleAuth.idToken != null) {
          await _supabase1.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );
          debugPrint('[AuthRepository] Supabase 1 client authenticated via silent Google Sign-In.');
        }
      }
    } catch (e) {
      debugPrint('[AuthRepository] Failed to recover Supabase 1 session silently: $e');
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

  /// Looks up one student through the resolve-student Edge Function, so the
  /// app never needs read access to the whole students table.
  Future<Map<String, dynamic>?> _getStudentByRollNo(String rollNo) async {
    try {
      final res = await _supabase1.functions.invoke(
        'resolve-student',
        body: {'roll_no': rollNo},
      );
      if (res.status != 200) return null;
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['found'] != true) return null;
      return data;
    } catch (e) {
      debugPrint('[AuthRepository] resolve-student failed: $e');
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
      // Don't clamp to 4 here: in Jan-Jun a 4th-year student has diff == 4,
      // giving 5 -> (2 * 5 - 2) = semester 8. The final clamp(1, 8) bounds it.
      batchNum = diff + 1;
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
