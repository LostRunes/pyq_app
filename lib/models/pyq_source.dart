class PyqSource {
  final String id;
  final String year;
  final String examType;
  final String season;
  final String questionNumber;

  PyqSource({
    required this.id,
    required this.year,
    required this.examType,
    required this.season,
    required this.questionNumber,
  });

  factory PyqSource.fromJson(Map<String, dynamic> json) => PyqSource(
        id: json['id']?.toString() ?? '',
        year: json['year']?.toString() ?? '',
        examType: json['exam_type'] ?? '',
        season: json['season'] ?? '',
        questionNumber: json['question_number']?.toString() ?? '',
      );
}
