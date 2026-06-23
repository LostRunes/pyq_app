import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/topic.dart';
import '../models/topic_resource.dart';
import '../models/question.dart';
import '../models/pyq_source.dart';
import '../models/image_item.dart';
import '../models/question_full.dart';
import '../models/topic_with_questions.dart';

class PyqRepository {
  final SupabaseClient _supabase;

  PyqRepository(this._supabase);

  Future<List<Topic>> getTopics(String subjectId) async {
    final res = await _supabase
        .from('topics')
        .select()
        .eq('subject_id', subjectId);
    return (res as List).map((e) => Topic.fromJson(e)).toList();
  }

  Future<List<Topic>> getTopicsWithImportance(String subjectId) async {
    // 1. Fetch topics
    final topics = await getTopics(subjectId);
    if (topics.isEmpty) return [];

    final topicIds = topics.map((t) => t.id).toList();

    // 2. Fetch all question_topics for these topics
    final qtRes = await _supabase
        .from('question_topics')
        .select('topic_id, question_id')
        .filter('topic_id', 'in', topicIds);
    final qtList = qtRes as List;

    final allQuestionIds = qtList.map((e) => e['question_id']).toSet().toList();
    if (allQuestionIds.isEmpty) return topics;

    // 3. Fetch all question_pyq_map with source years for these questions
    final qpmRes = await _supabase
        .from('question_pyq_map')
        .select('question_id, pyq_sources(year)')
        .filter('question_id', 'in', allQuestionIds);
    final qpmList = qpmRes as List;

    // 4. Calculate scores for each topic
    for (var topic in topics) {
      final topicQuestionIds = qtList
          .where((qt) => qt['topic_id'] == topic.id)
          .map((qt) => qt['question_id'])
          .toSet();

      final relatedPyqs = qpmList
          .where((qpm) => topicQuestionIds.contains(qpm['question_id']))
          .toList();

      final totalQuestions = topicQuestionIds.length;
      final totalPyqs = relatedPyqs.length;
      final uniqueYears = relatedPyqs
          .map((qpm) {
            final source = qpm['pyq_sources'];
            if (source is Map) return source['year'];
            if (source is List && source.isNotEmpty) return source[0]['year'];
            return null;
          })
          .whereType<int>()
          .toSet()
          .length;

      // Formula: score = (questions * 2) + (unique_years * 3) + (total_pyqs)
      double score = (totalQuestions * 2.0) + (uniqueYears * 3.0) + totalPyqs;
      topic.importanceScore = score;
    }

    return topics;
  }

  Future<List<TopicResource>> getTopicResources(String topicId) async {
    final res = await _supabase
        .from('topic_resources')
        .select()
        .eq('topic_id', topicId);
    return (res as List).map((e) => TopicResource.fromJson(e)).toList();
  }

  Future<List<Question>> getQuestionsByTopic(String topicId) async {
    final res = await _supabase
        .from('question_topics')
        .select(
          'questions(id, question_text, difficulty, question_pyq_map(pyq_sources(id, year, exam_type, season, question_number)))',
        )
        .eq('topic_id', topicId);
    return (res as List).map((e) => Question.fromJson(e['questions'])).toList();
  }

  Future<Question> getQuestionDetail(String questionId) async {
    final res = await _supabase
        .from('questions')
        .select()
        .eq('id', questionId)
        .single();
    return Question.fromJson(res);
  }

  Future<List<PyqSource>> getPyqSourcesForQuestion(String questionId) async {
    final res = await _supabase
        .from('question_pyq_map')
        .select('pyq_sources(id, year, exam_type, season, question_number)')
        .eq('question_id', questionId);
    return (res as List)
        .map((e) => PyqSource.fromJson(e['pyq_sources']))
        .toList();
  }

  Future<List<ImageItem>> getImagesForQuestion(String questionId) async {
    final res = await _supabase
        .from('images')
        .select()
        .eq('question_id', questionId)
        .order('order_index');
    return (res as List).map((e) => ImageItem.fromJson(e)).toList();
  }

  // Optimized Fetch for PDF using RPC functions
  Future<List<QuestionFull>> getQuestionsWithDetails(String topicId) async {
    try {
      final response = await _supabase.rpc(
        'get_topic_pdf_data',
        params: {'topic_uuid': topicId},
      );

      if (response == null) return [];

      final data = Map<String, dynamic>.from(response as Map);
      final questionsList = data['questions'] as List? ?? [];

      return questionsList.map((qJson) {
        final qMap = Map<String, dynamic>.from(qJson as Map);

        final images = qMap['images'] as List? ?? [];
        final imageUrls = images
            .map((i) {
              final iMap = Map<String, dynamic>.from(i as Map);
              return iMap['image_url']?.toString() ?? '';
            })
            .where((url) => url.isNotEmpty)
            .toList();

        final pyqs = qMap['pyq_meta'] as List? ?? [];
        final pyqMeta = pyqs.map((p) {
          final pMap = Map<String, dynamic>.from(p as Map);
          return PyqSource(
            id: '',
            year: pMap['year']?.toString() ?? '',
            examType: pMap['exam_type']?.toString() ?? '',
            season: pMap['season']?.toString() ?? '',
            questionNumber: pMap['question_number']?.toString() ?? '',
          );
        }).toList();

        return QuestionFull(
          text: qMap['text']?.toString() ?? '',
          difficulty: qMap['difficulty']?.toString() ?? '',
          imageUrls: imageUrls,
          pyqMeta: pyqMeta,
        );
      }).toList();
    } catch (e) {
      debugPrint(
        'RPC get_topic_pdf_data failed, falling back to legacy query: $e',
      );
      // Fallback in case RPC is not deployed yet or has error
      final questions = await getQuestionsByTopic(topicId);
      List<QuestionFull> fullQuestions = [];
      await Future.wait(
        questions.map((q) async {
          final pyqs = await getPyqSourcesForQuestion(q.id);
          final images = await getImagesForQuestion(q.id);
          fullQuestions.add(
            QuestionFull(
              text: q.questionText,
              difficulty: q.difficulty,
              imageUrls: images.map((i) => i.imageUrl).toList(),
              pyqMeta: pyqs,
            ),
          );
        }),
      );
      return fullQuestions;
    }
  }

  Future<List<TopicWithQuestions>> getFullSubjectData(String subjectId) async {
    try {
      final response = await _supabase.rpc(
        'get_subject_pdf_data',
        params: {'subject_uuid': subjectId},
      );

      if (response == null) return [];

      final List topicsList = response as List;

      return topicsList.map((tJson) {
        final tMap = Map<String, dynamic>.from(tJson as Map);
        final topicName = tMap['topic_name']?.toString() ?? '';

        final questionsList = tMap['questions'] as List? ?? [];
        final questions = questionsList.map((qJson) {
          final qMap = Map<String, dynamic>.from(qJson as Map);

          final images = qMap['images'] as List? ?? [];
          final imageUrls = images
              .map((i) {
                final iMap = Map<String, dynamic>.from(i as Map);
                return iMap['image_url']?.toString() ?? '';
              })
              .where((url) => url.isNotEmpty)
              .toList();

          final pyqs = qMap['pyq_meta'] as List? ?? [];
          final pyqMeta = pyqs.map((p) {
            final pMap = Map<String, dynamic>.from(p as Map);
            return PyqSource(
              id: '',
              year: pMap['year']?.toString() ?? '',
              examType: pMap['exam_type']?.toString() ?? '',
              season: pMap['season']?.toString() ?? '',
              questionNumber: pMap['question_number']?.toString() ?? '',
            );
          }).toList();

          return QuestionFull(
            text: qMap['text']?.toString() ?? '',
            difficulty: qMap['difficulty']?.toString() ?? '',
            imageUrls: imageUrls,
            pyqMeta: pyqMeta,
          );
        }).toList();

        return TopicWithQuestions(topicName: topicName, questions: questions);
      }).toList();
    } catch (e) {
      debugPrint(
        'RPC get_subject_pdf_data failed, falling back to legacy query: $e',
      );
      // Fallback to legacy behavior
      final topics = await getTopics(subjectId);
      final futures = topics.map((topic) async {
        final questions = await getQuestionsWithDetails(topic.id);
        return TopicWithQuestions(topicName: topic.name, questions: questions);
      }).toList();
      return await Future.wait(futures);
    }
  }
}
