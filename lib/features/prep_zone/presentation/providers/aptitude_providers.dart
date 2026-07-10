import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import '../../data/models/aptitude_question.dart';

class AptitudeService {
  Future<List<AptitudeQuestion>> fetchQuestions(String endpoint) async {
    final baseUrl = dotenv.env['APTITUDE_API_URL'] ?? 'https://aptitude-gold.vercel.app';
    final url = Uri.parse('$baseUrl/$endpoint');
    
    // Fire 20 requests concurrently
    final List<Future<http.Response>> requests = List.generate(
      20,
      (_) => http.get(url).timeout(const Duration(seconds: 8)),
    );
    
    // Prevent one failing request from crashing the entire batch
    final futures = requests.map((req) => req.catchError((_) => http.Response('', 500)));
    final responses = await Future.wait(futures);
    
    final List<AptitudeQuestion> questions = [];
    final Set<String> questionTexts = {};
    
    for (var response in responses) {
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final q = AptitudeQuestion.fromJson(data);
          if (q.question.isNotEmpty && !questionTexts.contains(q.question)) {
            questionTexts.add(q.question);
            questions.add(q);
          }
        } catch (_) {
          // Skip invalid JSON
        }
      }
    }
    
    if (questions.isEmpty) {
      throw Exception('Failed to load aptitude questions. Please check your connection.');
    }
    return questions;
  }
}

final aptitudeServiceProvider = Provider((ref) => AptitudeService());

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

