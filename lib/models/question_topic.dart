class QuestionTopic {
  final String questionId;
  final String topicId;

  QuestionTopic({required this.questionId, required this.topicId});

  factory QuestionTopic.fromJson(Map<String, dynamic> json) => QuestionTopic(
        questionId: json['question_id'] as String,
        topicId: json['topic_id'] as String,
      );
}
