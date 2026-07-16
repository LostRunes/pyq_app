import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/router.dart';
import '../features/skulk/study_together/data/models/study_room.dart';

/// Android notification channel used for all app notifications.
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'focus_fox_notifications', // Channel ID
  'General Notifications', // Channel Name
  description: 'Notifications for Focus Fox activity',
  importance: Importance.max,
);

const AndroidNotificationChannel _timerChannel = AndroidNotificationChannel(
  'focus_timer_channel_id',
  'Focus Timer Status',
  description: 'Ongoing notification for your active focus timer status',
  importance: Importance.low,
  playSound: false,
  enableVibration: false,
);

const AndroidNotificationChannel _timerCompleteChannel = AndroidNotificationChannel(
  'focus_timer_complete_channel_id',
  'Focus Timer Completion',
  description: 'Alerts when your focus timer finishes',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize Firebase Messaging and local notifications
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    // 1. Request permissions (essential for FCM)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted notification permissions.');
    }

    // 2. Local Notifications Setup
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction) {
          focusTimerActions.add(response.actionId!);
        } else {
          _handleNotificationTap(response.payload);
        }
      },
    );

    // Create the Android notification channels so they exist before any
    // notification is shown (required on Android 8+).
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_timerChannel);
    await androidPlugin?.createNotificationChannel(_timerCompleteChannel);

    // Explicitly request notification permissions on Android 13+
    await androidPlugin?.requestNotificationsPermission();

    // 3. Configure FCM Listeners

    // Foreground: app is open — show a local notification banner manually
    // because FCM suppresses the system tray in foreground by default.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Background tap: user tapped a notification while app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessageTap(message);
    });

    // Cold start: app was completely terminated and opened via notification tap.
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage);
    }

    _isInitialized = true;
  }

  /// Called by the top-level background handler in main.dart.
  /// Runs in a separate Dart isolate — no UI context is available.
  /// Initialises flutter_local_notifications (minimal setup) and shows a
  /// system-tray notification so the user sees it while the app is closed.
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInitSettings,
        iOS: DarwinInitializationSettings(),
      ),
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    await _showLocalNotification(message);
  }

  /// Display a local notification banner.
  /// Reads title/body from the data map (data-only messages) and falls
  /// back to the notification block for any legacy messages.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // Data-only message: title and body are inside message.data
    final String title =
        message.data['title'] as String? ??
        message.notification?.title ??
        'Focus Fox';
    final String body =
        message.data['body'] as String? ??
        message.notification?.body ??
        '';

    if (body.isEmpty) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/launcher_icon',
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    // Serialize data payload so it survives the tap callback.
    final String? payload =
        message.data.isNotEmpty ? message.data.toString() : null;

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }

  /// Handle tap on a local notification
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    // Parse simulated Map toString: {post_id: x, type: y, ...}
    try {
      final Map<String, String> data = {};
      final clean = payload.replaceAll('{', '').replaceAll('}', '');
      final parts = clean.split(',');
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          data[kv[0].trim()] = kv[1].trim();
        }
      }
      _navigateBasedOnData(data);
    } catch (e) {
      if (kDebugMode) print('Error parsing notification payload: $e');
    }
  }

  /// Handle tap on a background/terminated FCM notification
  static void _handleRemoteMessageTap(RemoteMessage message) {
    final Map<String, String> data =
        message.data.map((key, value) => MapEntry(key, value.toString()));
    _navigateBasedOnData(data);
  }

  /// Global router redirection helper
  static void _navigateBasedOnData(Map<String, String> data) async {
    final type = data['type'];
    final postId = data['post_id'];
    final notificationId = data['notification_id'];

    // Mark the notification as read in the database
    if (notificationId != null && notificationId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        await client
            .from('notifications')
            .update({'read': true})
            .eq('id', notificationId);
      } catch (e) {
        if (kDebugMode) print('Error marking notification as read: $e');
      }
    }

    if (postId == null || postId.isEmpty) return;

    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    if (type == 'mention' || type == 'tag' || type == 'grind_room') {
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('study_rooms')
            .select()
            .eq('id', postId)
            .maybeSingle();

        if (res != null && context.mounted) {
          final room = StudyRoom.fromJson(res);
          AppRouter.navigatorKey.currentState
              ?.pushNamed('/study-together/chat', arguments: room);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error navigating to study room from notification: $e');
        }
      }
    } else {
      AppRouter.navigatorKey.currentState
          ?.pushNamed('/skulk_detail', arguments: postId);
    }
  }

  /// Retrieves device FCM token and registers it to Supabase user_fcm_tokens
  static Future<void> registerDeviceToken() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('push_notifications') ?? true;
      if (!notificationsEnabled) {
        await deleteDeviceToken();
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? token = await _fcm.getToken();
      if (token == null) return;

      String deviceType = 'web';
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          deviceType = 'android';
        } else if (Platform.isIOS) {
          deviceType = 'ios';
        } else if (Platform.isMacOS) {
          deviceType = 'macos';
        } else if (Platform.isWindows) {
          deviceType = 'windows';
        }
      }

      await Supabase.instance.client.from('user_fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'device_type': deviceType,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');

      if (kDebugMode) print('FCM Token registered successfully: $token');
    } catch (e) {
      if (kDebugMode) print('Failed to register FCM token: $e');
    }
  }

  /// Discards the FCM token from Supabase upon logout
  static Future<void> deleteDeviceToken() async {
    if (kIsWeb) return;
    try {
      String? token = await _fcm.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from('user_fcm_tokens')
          .delete()
          .eq('token', token);

      if (kDebugMode) print('FCM Token unregistered successfully');
    } catch (e) {
      if (kDebugMode) print('Failed to unregister FCM token: $e');
    }
  }

  // ── FOCUS TIMER INTEGRATION ───────────────────────────────────────────────

  /// Global stream controller for forwarding notification action clicks.
  static final StreamController<String> focusTimerActions =
      StreamController<String>.broadcast();

  /// Displays or updates a persistent/ongoing notification with action buttons
  /// to control the active focus timer from the notification drawer.
  static Future<void> showFocusTimerNotification({
    required int secondsRemaining,
    required int durationSeconds,
    required bool isRunning,
  }) async {
    if (kIsWeb) return;

    final elapsed = durationSeconds - secondsRemaining;
    final int m = secondsRemaining ~/ 60;
    final int s = secondsRemaining % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'focus_timer_channel_id',
      'Focus Timer Status',
      channelDescription: 'Ongoing notification for your active focus timer',
      importance: Importance.low, // Keep low so it updates silently in tray
      priority: Priority.low,
      ongoing: true, // User cannot swipe it away
      onlyAlertOnce: true, // Prevents alert chime on every second tick
      showWhen: false,
      showProgress: true,
      maxProgress: durationSeconds,
      progress: elapsed,
      indeterminate: false,
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFFEC4899), // Pink brand color for progress bar
      actions: <AndroidNotificationAction>[
        if (isRunning)
          const AndroidNotificationAction(
            'pause',
            'Pause',
            showsUserInterface: true,
          )
        else
          const AndroidNotificationAction(
            'resume',
            'Resume',
            showsUserInterface: true,
          ),
        const AndroidNotificationAction(
          'end',
          'End Session',
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentSound: false,
      ),
    );

    await _localNotifications.show(
      id: 555, // Specific unique ID for the focus timer notification
      title: isRunning ? 'Focus Session Active' : 'Focus Session Paused',
      body: 'Time remaining: $timeStr',
      notificationDetails: platformDetails,
    );
  }

  /// Cancels the persistent focus timer notification.
  static Future<void> cancelFocusTimerNotification() async {
    if (kIsWeb) return;
    await _localNotifications.cancel(id: 555);
  }

  /// Displays a completion notification with alarm sound/vibration.
  static Future<void> showFocusTimerCompletionNotification() async {
    if (kIsWeb) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'focus_timer_complete_channel_id',
      'Focus Timer Completion',
      channelDescription: 'Alerts when your focus timer finishes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFFEC4899),
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: 556,
      title: 'Session Complete',
      body: 'Excellent focus! Take a well-deserved break.',
      notificationDetails: platformDetails,
    );
  }
}
