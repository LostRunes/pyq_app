class GateOption {
  final String id;
  final String optionLabel; // e.g. "A", "B"
  final String optionText;
  final bool isCorrect;

  GateOption({
    required this.id,
    required this.optionLabel,
    required this.optionText,
    required this.isCorrect,
  });

  factory GateOption.fromJson(Map<String, dynamic> json) {
    return GateOption(
      id: json['id'] ?? '',
      optionLabel: json['option_label'] ?? '',
      optionText: json['option_text'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }
}

class GateQuestionOccurrence {
  final String questionNumber;
  final int year;
  final String exam;

  GateQuestionOccurrence({
    required this.questionNumber,
    required this.year,
    required this.exam,
  });

  factory GateQuestionOccurrence.fromJson(Map<String, dynamic> json) {
    final paper = json['gate_papers'] as Map<String, dynamic>? ?? {};
    return GateQuestionOccurrence(
      questionNumber: json['question_number'] ?? '',
      year: paper['year'] as int? ?? 0,
      exam: paper['exam'] ?? '',
    );
  }
}

class GateQuestion {
  final String id;
  final String subjectId;
  final String questionText;
  final String questionType; // e.g. "MCQ", "NAT", "MSQ"
  final String difficulty;   // e.g. "easy", "medium", "hard"
  final double marks;
  final String? explanation;
  final String? correctAnswerText;
  final String? learningObjective;
  final String? revisionPriority;
  final String? bloomsTaxonomy;
  final bool isNumerical;
  final bool formulaBased;
  final int? estimatedSolveTimeSeconds;
  final List<GateOption> options;
  final List<String> concepts;
  final List<String> tags;
  final List<GateQuestionOccurrence> occurrences;

  GateQuestion({
    required this.id,
    required this.subjectId,
    required this.questionText,
    required this.questionType,
    required this.difficulty,
    required this.marks,
    this.explanation,
    this.correctAnswerText,
    this.learningObjective,
    this.revisionPriority,
    this.bloomsTaxonomy,
    required this.isNumerical,
    required this.formulaBased,
    this.estimatedSolveTimeSeconds,
    required this.options,
    required this.concepts,
    required this.tags,
    required this.occurrences,
  });

  factory GateQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['gate_options'] as List<dynamic>? ?? [];
    final optionsList = rawOptions.map((e) => GateOption.fromJson(e as Map<String, dynamic>)).toList();

    // Sort options by label if available (e.g. A, B, C, D)
    optionsList.sort((a, b) => a.optionLabel.compareTo(b.optionLabel));

    final rawConcepts = json['gate_question_concepts'] as List<dynamic>? ?? [];
    final conceptsList = rawConcepts
        .map((e) => e['gate_concepts']?['name']?.toString())
        .where((e) => e != null)
        .cast<String>()
        .toList();

    final rawTags = json['gate_question_tags'] as List<dynamic>? ?? [];
    final tagsList = rawTags
        .map((e) => e['gate_tags']?['name']?.toString())
        .where((e) => e != null)
        .cast<String>()
        .toList();

    final rawOccurrences = json['gate_question_occurrences'] as List<dynamic>? ?? [];
    final occurrencesList = rawOccurrences
        .map((e) => GateQuestionOccurrence.fromJson(e as Map<String, dynamic>))
        .toList();

    return GateQuestion(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      questionText: json['question_text'] ?? '',
      questionType: json['question_type'] ?? 'MCQ',
      difficulty: json['difficulty'] ?? 'medium',
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      explanation: json['explanation'],
      correctAnswerText: json['correct_answer_text'],
      learningObjective: json['learning_objective'],
      revisionPriority: json['revision_priority'],
      bloomsTaxonomy: json['blooms_taxonomy'],
      isNumerical: json['is_numerical'] ?? false,
      formulaBased: json['formula_based'] ?? false,
      estimatedSolveTimeSeconds: json['estimated_solve_time_seconds'] as int?,
      options: optionsList,
      concepts: conceptsList,
      tags: tagsList,
      occurrences: occurrencesList,
    );
  }
}
