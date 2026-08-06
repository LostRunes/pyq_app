import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  String get _apiKey => const String.fromEnvironment('GEMINI_API_KEY');
  static const String _primaryModel = "gemini-3.1-flash-lite-preview";

  Future<String> solveQuestion(String question) async {
    try {
      return await _callGemini(_primaryModel, question);
    } catch (e) {
      if (kDebugMode) print('AI Solver failed: $e');
      throw Exception(
        'Could not reach the AI solver. Please check your connection.',
      );
    }
  }

  Future<String> _callGemini(String model, String question) async {
    // Key in header — NOT in URL query param (prevents exposure in proxy logs
    // and server access logs where the full URL is recorded).
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    if (kDebugMode) print('Calling Gemini ($model)...');

    // Basic prompt injection guard: strip control sequences and limit length.
    final sanitizedQuestion = question
        .replaceAll(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]'), '')
        .trim()
        .substring(0, question.length.clamp(0, 4000));

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey, // key in header, not URL
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        """
Solve this engineering exam question step-by-step.

Format the answer using clean markdown:
- Use ## for sections (🧠 UNDERSTANDING, 📐 FORMULAS & STEPS, ✅ FINAL ANSWER)
- Use bullet points for steps
- Use short, clear paragraphs
- Keep it neat and exam-ready

Question:
$sanitizedQuestion
""",
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          "I couldn't generate a solution. Please try again.";
    } else {
      if (kDebugMode) print('Gemini API Error: ${response.statusCode}');
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}
