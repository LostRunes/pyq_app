class Subject {
  final String id;
  final String name;
  final String code;
  final String? pyqDriveLink;
  final String? notesDriveLink;
  final String? courseOutcomeLink;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    this.pyqDriveLink,
    this.notesDriveLink,
    this.courseOutcomeLink,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        pyqDriveLink: json['pyq_drive_link'] as String?,
        notesDriveLink: json['notes_drive_link'] as String?,
        courseOutcomeLink: json['course_outcome_link'] as String?,
      );
}
