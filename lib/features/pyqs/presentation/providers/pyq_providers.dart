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

final progressProvider = NotifierProvider<ProgressNotifier, Map<String, bool>>(
  ProgressNotifier.new,
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
