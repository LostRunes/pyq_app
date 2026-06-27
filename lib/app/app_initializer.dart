import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('dotenv load failed: $e');
    }

    try {
      final url = dotenv.env['SUPABASE_2_URL'] ?? '';
      final anonKey = dotenv.env['SUPABASE_2_KEY'] ?? '';
      if (url.isNotEmpty && anonKey.isNotEmpty) {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
        );
      } else {
        debugPrint('Supabase credentials missing in .env');
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
