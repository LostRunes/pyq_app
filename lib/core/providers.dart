import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../models/branch.dart';
import '../models/year.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/question.dart';
import '../models/pyq_source.dart';
import '../models/image_item.dart';
import '../models/topic_resource.dart';
import '../models/question_full.dart';
import '../models/topic_with_questions.dart';
import '../services/drive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());
final aiServiceProvider = Provider((ref) => AiService());
final driveServiceProvider = Provider((ref) => DriveService());

/// Fully signs the user out of both Google and Supabase.
/// Call this from any logout button. After this, the next Google sign-in
/// will always show the account picker (no silent re-auth).
Future<void> signOutCompletely() async {
  try {
    // 1. Revoke Google token so account picker shows next time
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  } catch (_) {
    // Ignore Google sign-out errors (user may not have used Google sign-in)
  }
  try {
    // 2. Sign out from Supabase (invalidates session server-side)
    await Supabase.instance.client.auth.signOut();
  } catch (_) {
    // Ignore Supabase sign-out errors
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_branch_id');
    await prefs.remove('selected_semester');
  } catch (_) {
    // Ignore SharedPreferences errors
  }
}

// Theme Mode Provider using the modern Notifier
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final branchesProvider = FutureProvider<List<Branch>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getBranches();
});

final yearsProvider = FutureProvider<List<Year>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getYears();
});

final subjectsProvider =
    FutureProvider.family<List<Subject>, ({String branchId, int semester})>((
      ref,
      arg,
    ) {
      final service = ref.watch(supabaseServiceProvider);
      return service.getSubjectsBySemester(
        branchId: arg.branchId,
        semester: arg.semester,
      );
    });

final allSubjectsProvider = FutureProvider<List<Subject>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getAllSubjects();
});

final topicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  subjectId,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getTopics(subjectId);
});

final dashboardTopicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  subjectId,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getTopicsWithImportance(subjectId);
});

final topicResourcesProvider =
    FutureProvider.family<List<TopicResource>, String>((ref, topicId) {
      final service = ref.watch(supabaseServiceProvider);
      return service.getTopicResources(topicId);
    });

final questionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  topicId,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getQuestionsByTopic(topicId);
});

final questionDetailProvider = FutureProvider.family<Question, String>((
  ref,
  questionId,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getQuestionDetail(questionId);
});

final pyqSourcesProvider = FutureProvider.family<List<PyqSource>, String>((
  ref,
  questionId,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getPyqSourcesForQuestion(questionId);
});

final imagesProvider = FutureProvider.family<List<ImageItem>, String>((
  ref,
  questionId,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getImagesForQuestion(questionId);
});

// PDF Loading State Provider
class PdfLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool value) => state = value;
}

final pdfLoadingProvider = NotifierProvider<PdfLoadingNotifier, bool>(
  PdfLoadingNotifier.new,
);

// Progress Tracking Provider
class ProgressNotifier extends Notifier<Map<String, bool>> {
  static const String _key = 'topic_progress';

  @override
  Map<String, bool> build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final String? data = prefs.getString(_key);
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = Map<String, dynamic>.from(
          Uri.decodeComponent(data).split(',').fold<Map<String, dynamic>>({}, (
            prev,
            element,
          ) {
            final parts = element.split(':');
            if (parts.length == 2) {
              prev[parts[0]] = parts[1] == 'true';
            }
            return prev;
          }),
        );
        return decoded.cast<String, bool>();
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  Future<void> toggleProgress(String topicId) async {
    final prefs = ref.read(sharedPrefsProvider);
    final newState = Map<String, bool>.from(state);
    newState[topicId] = !(state[topicId] ?? false);
    state = newState;

    final encoded = state.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(_key, Uri.encodeComponent(encoded));
  }

  bool isCompleted(String topicId) => state[topicId] ?? false;
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SelectedBranchIdNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getString('selected_branch_id') ?? '';
  }

  Future<void> setBranchId(String value) async {
    state = value;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('selected_branch_id', value);
  }
}

final selectedBranchIdProvider =
    NotifierProvider<SelectedBranchIdNotifier, String>(
      SelectedBranchIdNotifier.new,
    );

class SelectedSemesterNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getInt('selected_semester') ?? 1;
  }

  Future<void> setSemester(int value) async {
    state = value;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt('selected_semester', value);
  }
}

final selectedSemesterProvider =
    NotifierProvider<SelectedSemesterNotifier, int>(
      SelectedSemesterNotifier.new,
    );

final driveFolderContentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, folderId) {
      final service = ref.watch(driveServiceProvider);
      return service.fetchFolderContents(folderId);
    });

final subjectPdfDataProvider =
    FutureProvider.family<List<TopicWithQuestions>, String>((ref, subjectId) {
      final service = ref.watch(supabaseServiceProvider);
      return service.getFullSubjectData(subjectId);
    });

final topicPdfDataProvider = FutureProvider.family<List<QuestionFull>, String>((
  ref,
  topicId,
) {
  final service = ref.watch(supabaseServiceProvider);
  return service.getQuestionsWithDetails(topicId);
});

final progressProvider = NotifierProvider<ProgressNotifier, Map<String, bool>>(
  ProgressNotifier.new,
);

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return await Supabase.instance.client
      .from('user_profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
});
