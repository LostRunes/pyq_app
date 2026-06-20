import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> setUser(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {}
  }

  static Future<void> logLogin() async {
    try {
      await _analytics.logLogin();
    } catch (_) {}
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
  }

  static Future<void> logSearchPerformed(String searchTerm) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
      );
    } catch (_) {}
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
  }
}
