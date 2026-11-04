import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';
import '../firebase_options.dart';
import '../services/push_notification_service.dart';

class AppInitializer {
  static Future<SharedPreferences> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }

    final missing = Env.missingKeys;
    if (missing.isNotEmpty) {
      debugPrint(
        'Missing build config: ${missing.join(', ')}. '
        'Run with --dart-define-from-file=.env',
      );
    }

    try {
      if (Env.supabase2Url.isNotEmpty && Env.supabase2AnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: Env.supabase2Url,
          anonKey: Env.supabase2AnonKey,
        );
      } else {
        debugPrint('Supabase credentials missing: run with --dart-define-from-file=.env');
      }
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }

    try {
      // Initialize Push Notifications
      await PushNotificationService.initialize();
    } catch (e) {
      debugPrint('PushNotificationService initialization failed: $e');
    }

    return SharedPreferences.getInstance();
  }
}
