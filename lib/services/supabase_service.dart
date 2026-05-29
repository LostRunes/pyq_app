import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';
import '../models/year.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/question.dart';
import '../models/pyq_source.dart';
import '../models/image_item.dart';
import '../models/question_full.dart';
import '../models/topic_with_questions.dart';
import '../models/topic_resource.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Branch>> getBranches() async {
    final res = await supabase.from('branches').select();
    return (res as List).map((e) => Branch.fromJson(e)).toList();
  }

  Future<List<Year>> getYears() async {
    final res = await supabase.from('years').select();
    return (res as List).map((e) => Year.fromJson(e)).toList();
  }

  Future<List<Subject>> getSubjects({required String branchId, required String yearId}) async {
    final res = await supabase
        .from('branch_subjects')
        .select('subjects(id, name, code, pyq_drive_link, notes_drive_link, course_outcome_link), semester')
        .eq('branch_id', branchId)
        .eq('year_id', yearId);
    return (res as List)
        .map((e) => Subject.fromJson(e['subjects']))
        .toList();
  }

  Future<List<Topic>> getTopics(String subjectId) async {
    final res = await supabase.from('topics').select().eq('subject_id', subjectId);
    return (res as List).map((e) => Topic.fromJson(e)).toList();
  }

  Future<List<Topic>> getTopicsWithImportance(String subjectId) async {
    // 1. Fetch topics
    final topics = await getTopics(subjectId);
    if (topics.isEmpty) return [];

    final topicIds = topics.map((t) => t.id).toList();

    // 2. Fetch all question_topics for these topics
    final qtRes = await supabase
        .from('question_topics')
        .select('topic_id, question_id')
        .filter('topic_id', 'in', topicIds);
    final qtList = qtRes as List;

    final allQuestionIds = qtList.map((e) => e['question_id']).toSet().toList();
    if (allQuestionIds.isEmpty) return topics;

    // 3. Fetch all question_pyq_map with source years for these questions
    final qpmRes = await supabase
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
      
      // Normalize or cap if needed, for now we'll pass the raw score
      // We can normalize later in the UI relative to the max score in the list
      topic.importanceScore = score;
    }

    return topics;
  }

  Future<List<TopicResource>> getTopicResources(String topicId) async {
    final res = await supabase
        .from('topic_resources')
        .select()
        .eq('topic_id', topicId);
    return (res as List).map((e) => TopicResource.fromJson(e)).toList();
  }

  Future<List<Question>> getQuestionsByTopic(String topicId) async {
    final res = await supabase
        .from('question_topics')
        .select('questions(id, question_text, difficulty)')
        .eq('topic_id', topicId);
    return (res as List)
        .map((e) => Question.fromJson(e['questions']))
        .toList();
  }

  Future<Question> getQuestionDetail(String questionId) async {
    final res = await supabase.from('questions').select().eq('id', questionId).single();
    return Question.fromJson(res);
  }

  Future<List<PyqSource>> getPyqSourcesForQuestion(String questionId) async {
    final res = await supabase
        .from('question_pyq_map')
        .select('pyq_sources(id, year, exam_type, season, question_number)')
        .eq('question_id', questionId);
    return (res as List)
        .map((e) => PyqSource.fromJson(e['pyq_sources']))
        .toList();
  }

  Future<List<ImageItem>> getImagesForQuestion(String questionId) async {
    final res = await supabase
        .from('images')
        .select()
        .eq('question_id', questionId)
        .order('order_index');
    return (res as List).map((e) => ImageItem.fromJson(e)).toList();
  }

  // Optimized Fetch for PDF
  Future<List<QuestionFull>> getQuestionsWithDetails(String topicId) async {
    // 1. Get all questions for the topic
    final questions = await getQuestionsByTopic(topicId);
    
    List<QuestionFull> fullQuestions = [];
    
    // 2. Fetch details for each question (In parallel for speed)
    await Future.wait(questions.map((q) async {
      final pyqs = await getPyqSourcesForQuestion(q.id);
      final images = await getImagesForQuestion(q.id);
      
      fullQuestions.add(QuestionFull(
        text: q.questionText,
        difficulty: q.difficulty,
        imageUrls: images.map((i) => i.imageUrl).toList(),
        pyqMeta: pyqs,
      ));
    }));
    
    return fullQuestions;
  }

  Future<List<TopicWithQuestions>> getFullSubjectData(String subjectId) async {
    final topics = await getTopics(subjectId);
    
    // Parallelize API calls for all topics
    final futures = topics.map((topic) async {
      final questions = await getQuestionsWithDetails(topic.id);
      return TopicWithQuestions(
        topicName: topic.name,
        questions: questions,
      );
    }).toList();

    return await Future.wait(futures);
  }
}
