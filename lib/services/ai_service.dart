import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _primaryModel = "gemini-3.1-flash-lite-preview";

  Future<String> solveQuestion(String question) async {
    try {
      return await _callGemini(_primaryModel, question);
    } catch (e) {
      print('AI Solver failed: $e');
      throw Exception('Could not reach the AI solver. Please check your connection.');
    }
  }

  Future<String> _callGemini(String model, String question) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey",
    );

    print('Calling Gemini ($model)...');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': """
Solve this engineering exam question step-by-step.

Format the answer using clean markdown:
- Use ## for sections (🧠 UNDERSTANDING, 📐 FORMULAS & STEPS, ✅ FINAL ANSWER)
- Use bullet points for steps
- Use short, clear paragraphs
- Keep it neat and exam-ready

Question:
$question
"""
              }
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          "I couldn't generate a solution. Please try again.";
    } else {
      print("Gemini API Error Body: ${response.body}");
      throw Exception("API Error: ${response.statusCode}");
    }
  }
}
