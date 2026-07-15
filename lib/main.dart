import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'app/app_initializer.dart';
import 'firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/providers/prefs_provider.dart';
import 'services/push_notification_service.dart';
import 'features/subjects/data/models/branch.dart';
import 'features/subjects/data/models/year.dart';
import 'features/pyqs/data/models/subject.dart';
import 'features/pyqs/data/models/topic.dart';

/// Top-level background message handler.
/// MUST be a top-level function (not inside a class) and annotated with
/// @pragma('vm:entry-point') so the AOT compiler preserves it.
/// Firebase invokes this in a separate isolate when the app is terminated
/// or in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If the message contains a notification payload, the OS (Android/iOS) will
  // display it in the system tray automatically. Skip manual local notification to avoid duplicates.
  if (message.notification != null) return;

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

  // Initialize Hive
  await Hive.initFlutter();

  // Register Type Adapters
  Hive.registerAdapter(BranchAdapter());
  Hive.registerAdapter(YearAdapter());
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(TopicAdapter());

  // Open Boxes
  await Hive.openBox<Branch>('branches');
  await Hive.openBox<Year>('years');
  await Hive.openBox<Subject>('subjects');
  await Hive.openBox<Topic>('topics');

  usePathUrlStrategy();
  final prefs = await AppInitializer.initialize();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const PyqApp(),
    ),
  );
}
