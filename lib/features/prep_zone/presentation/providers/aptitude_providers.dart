import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers.dart';
import '../../data/models/aptitude_question.dart';

class AptitudeService {
  final SupabaseClient _client;

  AptitudeService(this._client);

  Future<List<AptitudeQuestion>> fetchQuestions(String endpoint) async {
    try {
      final response = await _client
          .from('aptitude_questions')
          .select('''
            question_text,
            explanation,
            aptitude_options (
              option_text,
              is_correct
            ),
            aptitude_topics!inner (
              slug
            )
          ''')
          .eq('aptitude_topics.slug', endpoint);

      final List<AptitudeQuestion> questions = [];
      final Set<String> questionTexts = {};

      for (final item in response as List<dynamic>) {
        final String questionText = item['question_text'] ?? '';
        final String? explanation = item['explanation'];

        final List<dynamic> optionsList = item['aptitude_options'] ?? [];
        final List<String> options = [];
        String correctAnswer = '';

        for (final opt in optionsList) {
          final String optText = opt['option_text'] ?? '';
          final bool isCorrect = opt['is_correct'] ?? false;
          options.add(optText);
          if (isCorrect) {
            correctAnswer = optText;
          }
        }

        if (questionText.isNotEmpty && !questionTexts.contains(questionText)) {
          questionTexts.add(questionText);
          questions.add(
            AptitudeQuestion(
              question: questionText,
              answer: correctAnswer,
              options: options,
              explanation: explanation,
            ),
          );
        }
      }

      if (questions.isEmpty) {
        throw Exception('No questions found for this topic.');
      }
      return questions;
    } catch (e) {
      throw Exception('Failed to load aptitude questions: $e');
    }
  }
}

final aptitudeServiceProvider = Provider((ref) => AptitudeService(ref.watch(supabase1ClientProvider)));

final aptitudeQuestionsProvider = FutureProvider.family<List<AptitudeQuestion>, String>((ref, endpoint) async {
  final service = ref.watch(aptitudeServiceProvider);
  return service.fetchQuestions(endpoint);
});

class AptitudeStats {
  final Map<String, Map<String, dynamic>> answers;
  final Map<String, List<String>> topicQuestions;

  AptitudeStats({
    required this.answers,
    required this.topicQuestions,
  });

  int get correctCount => answers.values.where((v) => v['isCorrect'] == true).length;
  int get incorrectCount => answers.values.where((v) => v['isCorrect'] == false).length;
  int get totalSolved => answers.length;
  int get totalScore => (correctCount * 4) - (incorrectCount * 1);

  int getSolvedCountForTopic(String topicEndpoint) {
    return topicQuestions[topicEndpoint]?.length ?? 0;
  }

  int getScoreForTopic(String topicEndpoint) {
    final questions = topicQuestions[topicEndpoint] ?? [];
    int score = 0;
    for (final qText in questions) {
      final ans = answers[qText];
      if (ans != null) {
        score += (ans['isCorrect'] == true) ? 4 : -1;
      }
    }
    return score;
  }
}

class AptitudeStatsNotifier extends Notifier<AptitudeStats> {
  static const _answersKey = 'aptitude_answers_v3';
  static const _topicsKey = 'aptitude_topics_v3';

  @override
  AptitudeStats build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final answersRaw = prefs.getString(_answersKey);
    final topicsRaw = prefs.getString(_topicsKey);

    Map<String, Map<String, dynamic>> answers = {};
    if (answersRaw != null) {
      try {
        final decoded = json.decode(answersRaw) as Map<String, dynamic>;
        answers = decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
      } catch (_) {}
    }

    Map<String, List<String>> topicQuestions = {};
    if (topicsRaw != null) {
      try {
        final decoded = json.decode(topicsRaw) as Map<String, dynamic>;
        topicQuestions = decoded.map((k, v) => MapEntry(k, List<String>.from(v as List)));
      } catch (_) {}
    }

    return AptitudeStats(answers: answers, topicQuestions: topicQuestions);
  }

  void recordAnswer({
    required String topicEndpoint,
    required String questionText,
    required String selectedOption,
    required bool isCorrect,
  }) {
    final newAnswers = Map<String, Map<String, dynamic>>.from(state.answers);
    newAnswers[questionText] = {
      'selectedOption': selectedOption,
      'isCorrect': isCorrect,
    };

    final newTopicQuestions = Map<String, List<String>>.from(state.topicQuestions);
    final topicList = List<String>.from(newTopicQuestions[topicEndpoint] ?? []);
    if (!topicList.contains(questionText)) {
      topicList.add(questionText);
    }
    newTopicQuestions[topicEndpoint] = topicList;

    state = AptitudeStats(answers: newAnswers, topicQuestions: newTopicQuestions);

    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_answersKey, json.encode(newAnswers));
    prefs.setString(_topicsKey, json.encode(newTopicQuestions));
  }
}

final aptitudeStatsProvider = NotifierProvider<AptitudeStatsNotifier, AptitudeStats>(
  AptitudeStatsNotifier.new,
);

