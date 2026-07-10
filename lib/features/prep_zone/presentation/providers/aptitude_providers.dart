import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
