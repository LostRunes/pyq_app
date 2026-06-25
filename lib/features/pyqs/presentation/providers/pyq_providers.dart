import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/providers/prefs_provider.dart';
import '../../data/models/topic.dart';
import '../../data/models/topic_resource.dart';
import '../../data/models/question.dart';
import '../../data/models/pyq_source.dart';
import '../../data/models/image_item.dart';
import '../../data/models/topic_with_questions.dart';
import '../../data/models/question_full.dart';

final topicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  subjectId,
) {
  final repository = ref.watch(pyqRepositoryProvider);
  return repository.getTopics(subjectId);
});

final dashboardTopicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  subjectId,
) {
  final repository = ref.watch(pyqRepositoryProvider);
  return repository.getTopicsWithImportance(subjectId);
});

final topicResourcesProvider =
    FutureProvider.family<List<TopicResource>, String>((ref, topicId) {
      final repository = ref.watch(pyqRepositoryProvider);
      return repository.getTopicResources(topicId);
    });

final questionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  topicId,
) {
  final repository = ref.watch(pyqRepositoryProvider);
  return repository.getQuestionsByTopic(topicId);
});

final questionDetailProvider = FutureProvider.family<Question, String>((
  ref,
  questionId,
) {
  final repository = ref.watch(pyqRepositoryProvider);
  return repository.getQuestionDetail(questionId);
});

final pyqSourcesProvider = FutureProvider.family<List<PyqSource>, String>((
  ref,
  questionId,
) {
  final repository = ref.watch(pyqRepositoryProvider);
  return repository.getPyqSourcesForQuestion(questionId);
});

final imagesProvider = FutureProvider.family<List<ImageItem>, String>((
  ref,
  questionId,
) {
  final repository = ref.watch(pyqRepositoryProvider);
  return repository.getImagesForQuestion(questionId);
});

class PdfLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool value) => state = value;
}

final pdfLoadingProvider = NotifierProvider<PdfLoadingNotifier, bool>(
  PdfLoadingNotifier.new,
);

class ProgressNotifier extends Notifier<Map<String, bool>> {
  static const String _key = 'topic_progress';

  @override
  Map<String, bool> build() {
    _syncFromSupabase();
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

  Future<void> _syncFromSupabase() async {
    final supabase = ref.read(supabase1ClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await supabase
          .from('student_topic_progress')
          .select('topic_id, is_completed')
          .eq('user_id', user.id);
      
      final prefs = ref.read(sharedPrefsProvider);
      final newState = Map<String, bool>.from(state);
      bool changed = false;

      for (final row in response) {
        final topicId = row['topic_id'] as String;
        final isCompleted = row['is_completed'] as bool;
        if (newState[topicId] != isCompleted) {
          newState[topicId] = isCompleted;
          changed = true;
        }
      }

      if (changed) {
        state = newState;
        final encoded = state.entries.map((e) => '${e.key}:${e.value}').join(',');
        await prefs.setString(_key, Uri.encodeComponent(encoded));
      }
    } catch (e) {
      // Ignore network errors
    }
  }

  Future<void> toggleProgress(String topicId) async {
    final prefs = ref.read(sharedPrefsProvider);
    final newState = Map<String, bool>.from(state);
    final isCompleted = !(state[topicId] ?? false);
    newState[topicId] = isCompleted;
    state = newState;

    final encoded = state.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(_key, Uri.encodeComponent(encoded));

    // Sync to Supabase
    final supabase = ref.read(supabase1ClientProvider);
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        await supabase.from('student_topic_progress').upsert({
          'user_id': user.id,
          'topic_id': topicId,
          'is_completed': isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  bool isCompleted(String topicId) => state[topicId] ?? false;
}

final progressProvider = NotifierProvider<ProgressNotifier, Map<String, bool>>(
  ProgressNotifier.new,
);

class TrackedTopicsNotifier extends Notifier<Set<String>> {
  static const String _key = 'tracked_topics';

  @override
  Set<String> build() {
    _syncFromSupabase();
    final prefs = ref.watch(sharedPrefsProvider);
    final List<String>? list = prefs.getStringList(_key);
    return list?.toSet() ?? {};
  }

  Future<void> _syncFromSupabase() async {
    final supabase = ref.read(supabase1ClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await supabase
          .from('student_topic_progress')
          .select('topic_id, is_tracked')
          .eq('user_id', user.id);
      
      final prefs = ref.read(sharedPrefsProvider);
      final newState = Set<String>.from(state);
      bool changed = false;

      for (final row in response) {
        final topicId = row['topic_id'] as String;
        final isTracked = row['is_tracked'] as bool;
        if (isTracked && !newState.contains(topicId)) {
          newState.add(topicId);
          changed = true;
        } else if (!isTracked && newState.contains(topicId)) {
          newState.remove(topicId);
          changed = true;
        }
      }

      if (changed) {
        state = newState;
        await prefs.setStringList(_key, newState.toList());
      }
    } catch (e) {
      // Ignore network errors
    }
  }

  Future<void> toggleTracked(String topicId) async {
    final prefs = ref.read(sharedPrefsProvider);
    final newState = Set<String>.from(state);
    bool isTracked = false;
    if (newState.contains(topicId)) {
      newState.remove(topicId);
      // If untracked, automatically uncheck/clear progress for this topic
      final progress = ref.read(progressProvider);
      if (progress[topicId] == true) {
        await ref.read(progressProvider.notifier).toggleProgress(topicId);
      }
    } else {
      newState.add(topicId);
      isTracked = true;
    }
    state = newState;
    await prefs.setStringList(_key, newState.toList());

    // Sync to Supabase
    final supabase = ref.read(supabase1ClientProvider);
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        await supabase.from('student_topic_progress').upsert({
          'user_id': user.id,
          'topic_id': topicId,
          'is_tracked': isTracked,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  Future<void> setAllTracked(List<String> topicIds, bool track) async {
    final prefs = ref.read(sharedPrefsProvider);
    final newState = Set<String>.from(state);
    if (track) {
      newState.addAll(topicIds);
    } else {
      newState.removeAll(topicIds);
      final progress = ref.read(progressProvider);
      for (final topicId in topicIds) {
        if (progress[topicId] == true) {
          await ref.read(progressProvider.notifier).toggleProgress(topicId);
        }
      }
    }
    state = newState;
    await prefs.setStringList(_key, newState.toList());
  }

  bool isTracked(String topicId) => state.contains(topicId);
}

final trackedTopicsProvider = NotifierProvider<TrackedTopicsNotifier, Set<String>>(
  TrackedTopicsNotifier.new,
);

class LeetCodeProgressNotifier extends Notifier<Map<String, bool>> {
  static const String _key = 'leetcode_progress';

  @override
  Map<String, bool> build() {
    _syncFromSupabase();
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

  Future<void> _syncFromSupabase() async {
    final supabase = ref.read(supabase1ClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await supabase
          .from('student_leetcode_progress')
          .select('leetcode_id, is_completed')
          .eq('user_id', user.id);
      
      final prefs = ref.read(sharedPrefsProvider);
      final newState = Map<String, bool>.from(state);
      bool changed = false;

      for (final row in response) {
        final leetcodeId = row['leetcode_id'].toString();
        final isCompleted = row['is_completed'] as bool;
        if (newState[leetcodeId] != isCompleted) {
          newState[leetcodeId] = isCompleted;
          changed = true;
        }
      }

      if (changed) {
        state = newState;
        final encoded = state.entries.map((e) => '${e.key}:${e.value}').join(',');
        await prefs.setString(_key, Uri.encodeComponent(encoded));
      }
    } catch (e) {
      // Ignore network errors
    }
  }

  Future<void> toggleProgress(String leetcodeId) async {
    final prefs = ref.read(sharedPrefsProvider);
    final newState = Map<String, bool>.from(state);
    final isCompleted = !(state[leetcodeId] ?? false);
    newState[leetcodeId] = isCompleted;
    state = newState;

    final encoded = state.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(_key, Uri.encodeComponent(encoded));

    // Sync to Supabase
    final supabase = ref.read(supabase1ClientProvider);
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        await supabase.from('student_leetcode_progress').upsert({
          'user_id': user.id,
          'leetcode_id': leetcodeId,
          'is_completed': isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  bool isCompleted(String leetcodeId) => state[leetcodeId] ?? false;
}

final leetCodeProgressProvider = NotifierProvider<LeetCodeProgressNotifier, Map<String, bool>>(
  LeetCodeProgressNotifier.new,
);

final driveFolderContentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, folderId) {
      final service = ref.watch(driveServiceProvider);
      return service.fetchFolderContents(folderId);
    });

final subjectPdfDataProvider =
    FutureProvider.family<List<TopicWithQuestions>, String>((ref, subjectId) {
      final repository = ref.watch(pyqRepositoryProvider);
      return repository.getFullSubjectData(subjectId);
    });

final topicPdfDataProvider = FutureProvider.family<List<QuestionFull>, String>((
  ref,
  topicId,
) {
  final repository = ref.watch(pyqRepositoryProvider);
  return repository.getQuestionsWithDetails(topicId);
});

final leetcodeQuestionsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabase1ClientProvider);
  final res = await supabase.from('leetcode').select('id, parent_topic');
  return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

final allTopicsListProvider = FutureProvider<List<Topic>>((ref) async {
  final supabase = ref.watch(supabase1ClientProvider);
  final res = await supabase.from('topics').select();
  return (res as List).map((e) => Topic.fromJson(e)).toList();
});

