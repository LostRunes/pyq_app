import 'package:hive/hive.dart';

part 'topic.g.dart';

@HiveType(typeId: 3)
class Topic extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String subjectId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String? summary;
  
  // Recalculated dynamically at runtime, so we do not store it in Hive.
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
