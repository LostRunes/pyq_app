import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logEvent({
    required String eventType,
    required String eventName,
    String? screenName,
    Map<String, dynamic>? metadata,
  }) async {
    // 1. Log to Supabase database (works on all platforms, including Windows)
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('user_analytics_events').insert({
        'user_id': user?.id,
        'event_type': eventType,
        'event_name': eventName,
        'screen_name': screenName,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      debugPrint('Failed to log event to Supabase: $e');
    }

    // 2. Log to Firebase Analytics (Android, iOS, Web, macOS)
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        // Skip Firebase Analytics on Windows as it is unsupported
        return;
      }
      await _analytics.logEvent(
        name: eventName.replaceAll('-', '_'), // Firebase requires alphanumeric/underscores
        parameters: {
          'event_type': eventType,
          'screen_name': ?screenName,
          ...?metadata,
        },
      );
    } catch (_) {}
  }

  static Future<void> setUser(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {}
    // Also track the identification event
    await logEvent(
      eventType: 'user_identify',
      eventName: 'identify',
      metadata: {'user_id': userId},
    );
  }

  static Future<void> logLogin() async {
    try {
      await _analytics.logLogin();
    } catch (_) {}
    await logEvent(
      eventType: 'auth',
      eventName: 'login',
    );
  }

  static Future<void> logSubjectOpened(String subjectName) async {
    try {
      await _analytics.logEvent(
        name: 'subject_opened',
        parameters: {
          'subject': subjectName,
        },
      );
    } catch (_) {}
    await logEvent(
      eventType: 'feature_use',
      eventName: 'subject_opened',
      metadata: {'subject': subjectName},
    );
  }

  static Future<void> logPyqViewed(String subjectName, String questionId) async {
    try {
      await _analytics.logEvent(
        name: 'pyq_viewed',
        parameters: {
          'subject': subjectName,
          'question_id': questionId,
        },
      );
    } catch (_) {}
    await logEvent(
      eventType: 'feature_use',
      eventName: 'pyq_viewed',
      metadata: {
        'subject': subjectName,
        'question_id': questionId,
      },
    );
  }

  static Future<void> logSearchPerformed(String searchTerm) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
      );
    } catch (_) {}
    await logEvent(
      eventType: 'feature_use',
      eventName: 'search',
      metadata: {'search_term': searchTerm},
    );
  }

  static Future<void> logNotesDownloaded(String fileName, String subjectName) async {
    try {
      await _analytics.logEvent(
        name: 'notes_downloaded',
        parameters: {
          'file_name': fileName,
          'subject': subjectName,
        },
      );
    } catch (_) {}
    await logEvent(
      eventType: 'feature_use',
      eventName: 'notes_downloaded',
      metadata: {
        'file_name': fileName,
        'subject': subjectName,
      },
    );
  }

  static Future<void> logFeatureUsed({
    required String featureName,
    String? screenName,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      eventType: 'feature_use',
      eventName: featureName,
      screenName: screenName,
      metadata: metadata,
    );
  }

  static Future<void> logClick({
    required String elementId,
    required String screenName,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      eventType: 'click',
      eventName: 'click_$elementId',
      screenName: screenName,
      metadata: metadata,
    );
  }
}

class CustomAnalyticsObserver extends NavigatorObserver {
  final Map<Route, DateTime> _routeEntryTimes = {};

  void _logScreenEntry(Route? route) {
    if (route is PageRoute && route.settings.name != null) {
      _routeEntryTimes[route] = DateTime.now();
      AnalyticsService.logEvent(
        eventType: 'page_entry',
        eventName: 'enter_screen',
        screenName: route.settings.name,
      );
    }
  }

  void _logScreenExit(Route? route) {
    if (route is PageRoute && route.settings.name != null) {
      final entryTime = _routeEntryTimes.remove(route);
      if (entryTime != null) {
        final duration = DateTime.now().difference(entryTime).inSeconds;
        AnalyticsService.logEvent(
          eventType: 'page_view',
          eventName: 'stay_duration',
          screenName: route.settings.name,
          metadata: {
            'duration_seconds': duration,
          },
        );
      }
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenExit(previousRoute);
    _logScreenEntry(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _logScreenExit(route);
    _logScreenEntry(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logScreenExit(oldRoute);
    _logScreenEntry(newRoute);
  }
}
