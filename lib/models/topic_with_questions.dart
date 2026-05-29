import 'question_full.dart';

class TopicWithQuestions {
  final String topicName;
  final List<QuestionFull> questions;

  TopicWithQuestions({
    required this.topicName,
    required this.questions,
  });
}
