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
    // 1. Fetch global default subjects
    final res = await _supabase
        .from('branch_subjects')
        .select(
          'subjects(id, name, code, pyq_drive_link, notes_drive_link, course_outcome_link, priority, subject_credit, subject_type)',
        )
        .eq('branch_id', branchId)
        .eq('semester', semester);
    
    final List<Subject> subjects = (res as List)
        .where((e) => e['subjects'] != null)
        .map((e) => Subject.fromJson(e['subjects']))
        .toList();

    // 2. Fetch user customizations if logged in
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final customRes = await _supabase
          .from('user_subject_customizations')
          .select(
            'action, subjects(id, name, code, pyq_drive_link, notes_drive_link, course_outcome_link, priority, subject_credit, subject_type)',
          )
          .eq('user_id', userId)
          .eq('branch_id', branchId)
          .eq('semester', semester);

      for (var custom in customRes as List) {
        final action = custom['action'] as String;
        final subjectData = custom['subjects'];
        if (subjectData == null) continue;
        final subject = Subject.fromJson(subjectData);

        if (action == 'add') {
          if (!subjects.any((s) => s.id == subject.id)) {
            subjects.add(subject);
          }
        } else if (action == 'remove') {
          subjects.removeWhere((s) => s.id == subject.id);
        }
      }
    }

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

  Future<void> deleteSubjectFromSemester({
    required String branchId,
    required int semester,
    required String subjectId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    // Check if there is an existing customization for this subject
    final existingCustom = await _supabase
        .from('user_subject_customizations')
        .select()
        .eq('user_id', userId)
        .eq('branch_id', branchId)
        .eq('semester', semester)
        .eq('subject_id', subjectId)
        .maybeSingle();

    if (existingCustom != null) {
      final action = existingCustom['action'] as String;
      if (action == 'add') {
        // If it was added, deleting the customization row reverts it to the default (not present)
        await _supabase
            .from('user_subject_customizations')
            .delete()
            .eq('id', existingCustom['id']);
        return;
      }
    }

    // Check if the subject is in the global branch_subjects (default)
    final existingGlobal = await _supabase
        .from('branch_subjects')
        .select()
        .eq('branch_id', branchId)
        .eq('semester', semester)
        .eq('subject_id', subjectId)
        .maybeSingle();

    if (existingGlobal != null) {
      // If it exists in the global syllabus, we insert a 'remove' customization to hide it for this user
      await _supabase.from('user_subject_customizations').insert({
        'user_id': userId,
        'branch_id': branchId,
        'semester': semester,
        'subject_id': subjectId,
        'action': 'remove',
      });
    }
  }

  Future<void> addSubjectToSemester({
    required String branchId,
    required int semester,
    required String subjectId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    // Check if there is an existing customization for this subject
    final existingCustom = await _supabase
        .from('user_subject_customizations')
        .select()
        .eq('user_id', userId)
        .eq('branch_id', branchId)
        .eq('semester', semester)
        .eq('subject_id', subjectId)
        .maybeSingle();

    if (existingCustom != null) {
      final action = existingCustom['action'] as String;
      if (action == 'remove') {
        // If it was removed, deleting the customization row reverts it to the default (added)
        await _supabase
            .from('user_subject_customizations')
            .delete()
            .eq('id', existingCustom['id']);
        return;
      }
    }

    // Check if the subject is already in the global branch_subjects (default)
    final existingGlobal = await _supabase
        .from('branch_subjects')
        .select()
        .eq('branch_id', branchId)
        .eq('semester', semester)
        .eq('subject_id', subjectId)
        .maybeSingle();

    if (existingGlobal != null) {
      // It's already there globally, so nothing to add
      return;
    }

    // Otherwise, insert an 'add' customization
    await _supabase.from('user_subject_customizations').insert({
      'user_id': userId,
      'branch_id': branchId,
      'semester': semester,
      'subject_id': subjectId,
      'action': 'add',
    });
  }
}
