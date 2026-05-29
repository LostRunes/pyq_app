class BranchSubject {
  final String id;
  final String branchId;
  final String subjectId;
  final String yearId;
  final int semester;

  BranchSubject({
    required this.id,
    required this.branchId,
    required this.subjectId,
    required this.yearId,
    required this.semester,
  });

  factory BranchSubject.fromJson(Map<String, dynamic> json) => BranchSubject(
        id: json['id'] as String,
        branchId: json['branch_id'] as String,
        subjectId: json['subject_id'] as String,
        yearId: json['year_id'] as String,
        semester: json['semester'] as int,
      );
}
