import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';
import '../models/year.dart';
import '../../../pyqs/data/models/subject.dart';

class SubjectsRepository {
  final SupabaseClient _supabase;

  SubjectsRepository(this._supabase);

  Future<List<Branch>> getBranches() async {
    final res = await _supabase.from('branches').select();
    return (res as List).map((e) => Branch.fromJson(e)).toList();
  }

  Future<List<Year>> getYears() async {
    final res = await _supabase.from('years').select();
    return (res as List).map((e) => Year.fromJson(e)).toList();
  }

  Future<List<Subject>> getSubjectsBySemester({
    required String branchId,
    required int semester,
  }) async {
    final res = await _supabase
        .from('branch_subjects')
        .select(
          'subjects(id, name, code, pyq_drive_link, notes_drive_link, course_outcome_link, priority, subject_credit, subject_type)',
        )
        .eq('branch_id', branchId)
        .eq('semester', semester);
    final subjects = (res as List)
        .map((e) => Subject.fromJson(e['subjects']))
        .toList();
    subjects.sort((a, b) {
      if (a.priority == null && b.priority == null) return 0;
      if (a.priority == null) return 1;
      if (b.priority == null) return -1;
      return a.priority!.compareTo(b.priority!);
    });
    return subjects;
  }

  Future<List<Subject>> getAllSubjects() async {
    final res = await _supabase
        .from('subjects')
        .select(
          'id, name, code, pyq_drive_link, notes_drive_link, course_outcome_link, priority, subject_credit, subject_type',
        );
    final subjects = (res as List).map((e) => Subject.fromJson(e)).toList();
    subjects.sort((a, b) {
      if (a.priority == null && b.priority == null) return 0;
      if (a.priority == null) return 1;
      if (b.priority == null) return -1;
      return a.priority!.compareTo(b.priority!);
    });
    return subjects;
  }

  Future<Map<String, dynamic>?> getStudentByRollNo(String rollNo) async {
    try {
      final res = await _supabase
          .from('students')
          .select()
          .eq('roll_no', rollNo)
          .maybeSingle();
      return res;
    } catch (e) {
      return null;
    }
  }

  Future<String> getBranchIdFromSection(String section) async {
    try {
      final res = await getBranches();
      if (res.isEmpty) return '';

      final secUpper = section.toUpperCase();

      for (var branch in res) {
        final nameUpper = branch.name.toUpperCase();
        if (secUpper.contains(nameUpper) || nameUpper.contains(secUpper)) {
          return branch.id;
        }
      }

      if (secUpper.startsWith('B') && RegExp(r'^B\d+$').hasMatch(secUpper)) {
        final cseBranch = res.firstWhere(
          (b) => b.name.toUpperCase().contains('CS'),
          orElse: () => res.first,
        );
        return cseBranch.id;
      }

      return res.first.id;
    } catch (e) {
      return '';
    }
  }
}
