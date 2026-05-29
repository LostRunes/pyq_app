import 'pyq_source.dart';

class Question {
  final String id;
  final String questionText;
  final String difficulty;
  final List<PyqSource> pyqSources;

  Question({
    required this.id,
    required this.questionText,
    required this.difficulty,
    this.pyqSources = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var pyqList = const <PyqSource>[];
    if (json['question_pyq_map'] != null) {
      final mapList = json['question_pyq_map'] as List;
      pyqList = mapList
          .map((e) {
            final source = e['pyq_sources'];
            if (source == null) return null;
            if (source is List) {
              return source.isNotEmpty ? PyqSource.fromJson(source[0]) : null;
            }
            return PyqSource.fromJson(source);
          })
          .whereType<PyqSource>()
          .toList();
    }
    return Question(
      id: json['id'] as String,
      questionText: json['question_text'] as String,
      difficulty: json['difficulty'] as String,
      pyqSources: pyqList,
    );
  }
}
