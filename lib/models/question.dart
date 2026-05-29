class Question {
  final String id;
  final String questionText;
  final String difficulty;

  Question({required this.id, required this.questionText, required this.difficulty});

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        questionText: json['question_text'] as String,
        difficulty: json['difficulty'] as String,
      );
}
