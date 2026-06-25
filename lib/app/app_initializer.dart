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
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_2_URL']!,
      anonKey: dotenv.env['SUPABASE_2_KEY']!,
    );

    // Initialize Push Notifications
    await PushNotificationService.initialize();

    return SharedPreferences.getInstance();
  }
}
