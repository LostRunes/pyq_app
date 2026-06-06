import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final supabase = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_KEY']!,
  );

  Future<Map<String, dynamic>?> getStudentByRollNo(String rollNo) async {
    try {
      final res = await supabase
          .from('students')
          .select()
          .eq('roll_no', rollNo)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error searching students by roll_no: $e');
      return null;
    }
  }

  Future<String> getBranchIdFromSection(String section) async {
    try {
      final branches = await getBranches();
      if (branches.isEmpty) return '';

      final secUpper = section.toUpperCase();

      // Check direct matches (e.g., if section contains branch name like "CSE", "ECSC", "ME", etc.)
      for (var branch in branches) {
        final nameUpper = branch.name.toUpperCase();
        if (secUpper.contains(nameUpper) || nameUpper.contains(secUpper)) {
          return branch.id;
        }
      }

      // Handle special KIIT CSE section pattern "B[number]" (e.g. B10, B2)
      if (secUpper.startsWith('B') && RegExp(r'^B\d+$').hasMatch(secUpper)) {
        final cseBranch = branches.firstWhere(
          (b) => b.name.toUpperCase().contains('CS'),
          orElse: () => branches.first,
        );
        return cseBranch.id;
      }

      // Default fallback: first branch in list
      return branches.first.id;
    } catch (e) {
      debugPrint('Error mapping branch dynamically: $e');
      return '';
    }
  }


  Future<List<Branch>> getBranches() async {

    final res = await supabase.from('branches').select();
    return (res as List).map((e) => Branch.fromJson(e)).toList();
  }

  Future<List<Year>> getYears() async {
    final res = await supabase.from('years').select();
    return (res as List).map((e) => Year.fromJson(e)).toList();
  }

  Future<List<Subject>> getSubjectsBySemester({required String branchId, required int semester}) async {
    final res = await supabase
        .from('branch_subjects')
        .select('subjects(id, name, code, pyq_drive_link, notes_drive_link, course_outcome_link, priority, subject_credit, subject_type)')
        .eq('branch_id', branchId)
        .eq('semester', semester);
    final subjects = (res as List)
        .map((e) => Subject.fromJson(e['subjects']))
        .toList();
    subjects.sort((a, b) {
      if (a.priority == null && b.priority == null) return 0;
      if (a.priority == null) return 1;
      if (b.priority == null) return -1;
      return a.priority!.compareTo(b.priority!);
    });
    return subjects;
  }

  Future<List<Subject>> getAllSubjects() async {
    try {
      final res = await supabase.from('subjects').select('id, name, code, pyq_drive_link, notes_drive_link, course_outcome_link, priority, subject_credit, subject_type');
      final subjects = (res as List).map((e) => Subject.fromJson(e)).toList();
      subjects.sort((a, b) {
        if (a.priority == null && b.priority == null) return 0;
        if (a.priority == null) return 1;
        if (b.priority == null) return -1;
        return a.priority!.compareTo(b.priority!);
      });
      return subjects;
    } catch (e) {
      debugPrint('Error getting all subjects: $e');
      return [];
    }
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
        .select('questions(id, question_text, difficulty, question_pyq_map(pyq_sources(id, year, exam_type, season, question_number)))')
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

  // Optimized Fetch for PDF using RPC functions
  Future<List<QuestionFull>> getQuestionsWithDetails(String topicId) async {
    try {
      final response = await supabase.rpc(
        'get_topic_pdf_data',
        params: {
          'topic_uuid': topicId,
        },
      );

      if (response == null) return [];

      final data = Map<String, dynamic>.from(response as Map);
      final questionsList = data['questions'] as List? ?? [];

      return questionsList.map((qJson) {
        final qMap = Map<String, dynamic>.from(qJson as Map);

        final images = qMap['images'] as List? ?? [];
        final imageUrls = images.map((i) {
          final iMap = Map<String, dynamic>.from(i as Map);
          return iMap['image_url']?.toString() ?? '';
        }).where((url) => url.isNotEmpty).toList();

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
      debugPrint('RPC get_topic_pdf_data failed, falling back to legacy query: $e');
      // Fallback in case RPC is not deployed yet or has error
      final questions = await getQuestionsByTopic(topicId);
      List<QuestionFull> fullQuestions = [];
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
  }

  Future<List<TopicWithQuestions>> getFullSubjectData(String subjectId) async {
    try {
      final response = await supabase.rpc(
        'get_subject_pdf_data',
        params: {
          'subject_uuid': subjectId,
        },
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
          final imageUrls = images.map((i) {
            final iMap = Map<String, dynamic>.from(i as Map);
            return iMap['image_url']?.toString() ?? '';
          }).where((url) => url.isNotEmpty).toList();

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

        return TopicWithQuestions(
          topicName: topicName,
          questions: questions,
        );
      }).toList();
    } catch (e) {
      debugPrint('RPC get_subject_pdf_data failed, falling back to legacy query: $e');
      // Fallback to legacy behavior
      final topics = await getTopics(subjectId);
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
}
