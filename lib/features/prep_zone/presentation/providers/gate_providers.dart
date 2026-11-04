import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers.dart';
import '../../data/models/gate_question.dart';

class GateService {
  final SupabaseClient _client;

  GateService(this._client);

  Future<List<Map<String, dynamic>>> fetchSubjects() async {
    try {
      final response = await _client
          .from('gate_subjects')
          .select()
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load GATE subjects: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPapers() async {
    try {
      final response = await _client
          .from('gate_papers')
          .select()
          .order('year', ascending: false)
          .order('set_number', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load GATE papers: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopics(String subjectId) async {
    try {
      final response = await _client
          .from('gate_topics')
          .select()
          .eq('subject_id', subjectId)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load GATE topics: $e');
    }
  }

  Future<List<GateQuestion>> fetchQuestionsByTopic(String topicId) async {
    try {
      final response = await _client.from('gate_questions').select('''
        *,
        gate_options (
          id,
          option_label,
          option_text,
          is_correct
        ),
        gate_question_concepts (
          gate_concepts (
            name
          )
        ),
        gate_question_tags (
          gate_tags (
            name
          )
        ),
        gate_question_occurrences (
          question_number,
          gate_papers (
            year,
            exam
          )
        ),
        gate_question_topics!inner (
          topic_id
        )
      ''').eq('gate_question_topics.topic_id', topicId);

      final list = (response as List<dynamic>)
          .map((e) => GateQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortQuestionsSequentially(list);
      return list;
    } catch (e) {
      throw Exception('Failed to load GATE questions by topic: $e');
    }
  }

  Future<List<GateQuestion>> fetchQuestionsByPaper(String paperId) async {
    try {
      final response = await _client.from('gate_questions').select('''
        *,
        gate_options (
          id,
          option_label,
          option_text,
          is_correct
        ),
        gate_question_concepts (
          gate_concepts (
            name
          )
        ),
        gate_question_tags (
          gate_tags (
            name
          )
        ),
        gate_question_occurrences!inner (
          paper_id,
          question_number,
          gate_papers (
            year,
            exam
          )
        )
      ''').eq('gate_question_occurrences.paper_id', paperId);

      final list = (response as List<dynamic>)
          .map((e) => GateQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortQuestionsSequentially(list);
      return list;
    } catch (e) {
      throw Exception('Failed to load GATE questions by paper: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchYearAnalysis(String subjectId) async {
    try {
      final response = await _client
          .from('gate_year_analysis')
          .select()
          .eq('subject_id', subjectId);

      final papers = await fetchPapers();
      final paperMap = {for (var p in papers) p['id'] as String: p};

      final list = (response as List<dynamic>).map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final paperId = row['paper_id'] as String?;
        if (paperId != null && paperMap.containsKey(paperId)) {
          row['gate_papers'] = paperMap[paperId];
        }
        return row;
      }).toList();

      list.sort((a, b) {
        final paperA = a['gate_papers'] as Map<String, dynamic>?;
        final paperB = b['gate_papers'] as Map<String, dynamic>?;
        final yearA = paperA?['year'] as int? ?? 0;
        final yearB = paperB?['year'] as int? ?? 0;
        if (yearA != yearB) return yearA.compareTo(yearB);
        final setA = paperA?['set_number'] as int? ?? 0;
        final setB = paperB?['set_number'] as int? ?? 0;
        return setA.compareTo(setB);
      });
      return list;
    } catch (e) {
      throw Exception('Failed to load GATE year analysis: $e');
    }
  }

  static int _naturalCompare(String a, String b) {
    final reg = RegExp(r'(\d+|\D+)');
    final matchesA = reg.allMatches(a).map((m) => m.group(0)!).toList();
    final matchesB = reg.allMatches(b).map((m) => m.group(0)!).toList();

    for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final partA = matchesA[i];
      final partB = matchesB[i];

      final intA = int.tryParse(partA);
      final intB = int.tryParse(partB);

      if (intA != null && intB != null) {
        if (intA != intB) return intA.compareTo(intB);
      } else {
        final comp = partA.compareTo(partB);
        if (comp != 0) return comp;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
  }

  static void _sortQuestionsSequentially(List<GateQuestion> questions) {
    questions.sort((a, b) {
      final aNum = a.occurrences.isNotEmpty ? a.occurrences.first.questionNumber : '';
      final bNum = b.occurrences.isNotEmpty ? b.occurrences.first.questionNumber : '';
      return _naturalCompare(aNum, bNum);
    });
  }
}

final gateServiceProvider = Provider((ref) => GateService(ref.watch(supabase1ClientProvider)));

final gateSubjectsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(gateServiceProvider).fetchSubjects();
});

final gatePapersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(gateServiceProvider).fetchPapers();
});

final gateTopicsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, subjectId) async {
  return ref.watch(gateServiceProvider).fetchTopics(subjectId);
});

final gateQuestionsByTopicProvider = FutureProvider.family<List<GateQuestion>, String>((ref, topicId) async {
  return ref.watch(gateServiceProvider).fetchQuestionsByTopic(topicId);
});

final gateQuestionsByPaperProvider = FutureProvider.family<List<GateQuestion>, String>((ref, paperId) async {
  return ref.watch(gateServiceProvider).fetchQuestionsByPaper(paperId);
});

final gateYearAnalysisProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, subjectId) async {
  return ref.watch(gateServiceProvider).fetchYearAnalysis(subjectId);
});

// GATE statistics and answered tracking
class GateStats {
  final Map<String, Map<String, dynamic>> answers; // questionId -> { selected: String, isCorrect: bool }

  GateStats({required this.answers});

  int get correctCount => answers.values.where((v) => v['isCorrect'] == true).length;
  int get incorrectCount => answers.values.where((v) => v['isCorrect'] == false).length;
  int get totalSolved => answers.length;
  double get totalScore {
    double score = 0;
    answers.forEach((qId, val) {
      final rawIsCorrect = val['isCorrect'];
      final bool isCorrect = rawIsCorrect is bool
          ? rawIsCorrect
          : (rawIsCorrect is num ? rawIsCorrect > 0 : false);
      final marks = (val['marks'] as num?)?.toDouble() ?? 1.0;
      if (isCorrect) {
        score += marks;
      } else {
        // GATE has negative marking: -1/3 of marks for 1 mark, -2/3 for 2 marks
        // To be safe and align with exam standard:
        score -= (marks / 3);
      }
    });
    return score;
  }
}

class GateStatsNotifier extends Notifier<GateStats> {
  static const _answersKey = 'gate_answers_v1';

  @override
  GateStats build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final answersRaw = prefs.getString(_answersKey);

    Map<String, Map<String, dynamic>> answers = {};
    if (answersRaw != null) {
      try {
        final decoded = json.decode(answersRaw) as Map<String, dynamic>;
        answers = decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
      } catch (_) {}
    }

    return GateStats(answers: answers);
  }

  void recordAnswer({
    required String questionId,
    required String selectedAnswer,
    required bool isCorrect,
    required double marks,
  }) {
    final newAnswers = Map<String, Map<String, dynamic>>.from(state.answers);
    newAnswers[questionId] = {
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'marks': marks,
    };

    state = GateStats(answers: newAnswers);

    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_answersKey, json.encode(newAnswers));
  }
}

final gateStatsProvider = NotifierProvider<GateStatsNotifier, GateStats>(
  GateStatsNotifier.new,
);
