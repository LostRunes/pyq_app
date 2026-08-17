import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 2)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String code;
  @HiveField(3)
  final String? pyqDriveLink;
  @HiveField(4)
  final String? notesDriveLink;
  @HiveField(5)
  final String? courseOutcomeLink;
  @HiveField(6)
  final int? priority;
  @HiveField(7)
  final int? subjectCredit;
  @HiveField(8)
  final String? subjectType;
  @HiveField(9)
  final List<String>? ytLinks;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    this.pyqDriveLink,
    this.notesDriveLink,
    this.courseOutcomeLink,
    this.priority,
    this.subjectCredit,
    this.subjectType,
    this.ytLinks,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
    pyqDriveLink: json['pyq_drive_link'] as String?,
    notesDriveLink: json['notes_drive_link'] as String?,
    courseOutcomeLink: json['course_outcome_link'] as String?,
    priority: json['priority'] as int?,
    subjectCredit: json['subject_credit'] as int?,
    subjectType: json['subject_type'] as String?,
    ytLinks: (json['yt_links'] as List<dynamic>?)?.map((e) => e as String).toList(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
