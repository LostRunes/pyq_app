class Topic {
  final String id;
  final String subjectId;
  final String name;
  final String? summary;
  double importanceScore;

  Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    this.summary,
    this.importanceScore = 0.0,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        subjectId: json['subject_id'] as String,
        name: json['name'] as String,
        summary: json['summary'] as String?,
        importanceScore: 0.0,
      );
}
