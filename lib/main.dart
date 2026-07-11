import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/app_initializer.dart';
import 'firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/providers/prefs_provider.dart';
import 'services/push_notification_service.dart';

/// Top-level background message handler.
/// MUST be a top-level function (not inside a class) and annotated with
/// @pragma('vm:entry-point') so the AOT compiler preserves it.
/// Firebase invokes this in a separate isolate when the app is terminated
/// or in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be re-initialized in the background isolate.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Show a local notification so the user sees it in the system tray.
  await PushNotificationService.showBackgroundNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the background handler BEFORE Firebase.initializeApp() or runApp().
  // This is a strict Firebase requirement.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  usePathUrlStrategy();
  final prefs = await AppInitializer.initialize();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const PyqApp(),
    ),
  );
}
