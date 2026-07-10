class AptitudeQuestion {
  final String question;
  final String answer;
  final List<String> options;
  final String? explanation;

  AptitudeQuestion({
    required this.question,
    required this.answer,
    required this.options,
    this.explanation,
  });

  factory AptitudeQuestion.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((o) => o.toString()).toList();
    }
    
    return AptitudeQuestion(
      question: json['question'] ?? '',
      answer: json['answer']?.toString() ?? '',
      options: parsedOptions,
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'options': options,
      'explanation': explanation,
    };
  }
}
