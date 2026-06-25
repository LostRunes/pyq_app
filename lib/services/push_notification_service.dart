import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/router.dart';
import '../features/skulk/study_together/data/models/study_room.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  /// Initialize Firebase Messaging and local notifications
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    // 1. Request permissions (essential for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permissions.');
      }
    }

    // 2. Local Notifications Setup for foreground notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // 3. Configure FCM Listeners
    // Triggered when the app is in foreground and a message arrives
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Triggered when the user taps on a notification and the app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessageTap(message);
    });

    // Handle cold start (app was completely terminated and opened via notification)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage);
    }

    _isInitialized = true;
  }

  /// Display a local notification banner when the app is in the foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'focus_fox_notifications', // Channel ID
        'General Notifications', // Channel Name
        channelDescription: 'Notifications for Focus Fox activity',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      // Serialize data payload as a string to pass it to onDidReceiveNotificationResponse
      final String? payload = message.data.isNotEmpty ? message.data.toString() : null;

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    }
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
      if (kDebugMode) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle tap on a background/terminated FCM notification
  static void _handleRemoteMessageTap(RemoteMessage message) {
    final Map<String, String> data = message.data.map((key, value) => MapEntry(key, value.toString()));
    _navigateBasedOnData(data);
  }

  /// Global router redirection helper
  static void _navigateBasedOnData(Map<String, String> data) async {
    final type = data['type'];
    final postId = data['post_id'];

    if (postId == null || postId.isEmpty) return;

    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    if (type == 'mention' || type == 'tag') {
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('study_rooms')
            .select()
            .eq('id', postId)
            .maybeSingle();

        if (res != null && context.mounted) {
          final room = StudyRoom.fromJson(res);
          AppRouter.navigatorKey.currentState?.pushNamed('/study-together/chat', arguments: room);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error navigating to study room from notification: $e');
        }
      }
    } else {
      AppRouter.navigatorKey.currentState?.pushNamed('/skulk_detail', arguments: postId);
    }
  }

  /// Retrieves device FCM token and registers it to Supabase user_fcm_tokens
  static Future<void> registerDeviceToken() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('push_notifications') ?? true;
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
      
      if (kDebugMode) {
        print('FCM Token registered successfully: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register FCM token: $e');
      }
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

      if (kDebugMode) {
        print('FCM Token unregistered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to unregister FCM token: $e');
      }
    }
  }
}
