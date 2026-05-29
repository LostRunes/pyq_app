class QuestionPyqMap {
  final String questionId;
  final String pyqSourceId;

  QuestionPyqMap({required this.questionId, required this.pyqSourceId});

  factory QuestionPyqMap.fromJson(Map<String, dynamic> json) => QuestionPyqMap(
        questionId: json['question_id'] as String,
        pyqSourceId: json['pyq_source_id'] as String,
      );
}
