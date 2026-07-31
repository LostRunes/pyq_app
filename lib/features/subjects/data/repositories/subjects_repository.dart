import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';
import '../models/year.dart';
import '../../../pyqs/data/models/subject.dart';
import '../../../../core/network/supabase_rest_client.dart';
import '../../../../utils/first_year_branch_mapper.dart';

class SubjectsRepository {
  final SupabaseClient _supabase;
  final SupabaseRestClient _rest = SupabaseRestClient.instance;

  SubjectsRepository(this._supabase);

  // ── Hive box accessors ────────────────────────────────────────────────────
  Box<Branch> get _branchBox => Hive.box<Branch>('branches');
  Box<Year> get _yearBox => Hive.box<Year>('years');
  Box<Subject> get _subjectBox => Hive.box<Subject>('subjects');

  // ── BRANCHES ─────────────────────────────────────────────────────────────

  /// Returns cached branches instantly, refreshes in background.
  Future<List<Branch>> getBranches() async {
    // 1. Return cache if available
    if (_branchBox.isNotEmpty) {
      _refreshBranches(); // fire-and-forget
      return _branchBox.values.toList();
    }
    // 2. First run: must fetch from network before returning
    return _refreshBranches();
  }

  Future<List<Branch>> _refreshBranches() async {
    try {
      final raw = await _rest.getList('branches?select=id,name');
      final fresh = raw.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
      // Write to cache (keyed by id for easy lookup)
      await _branchBox.clear();
      await _branchBox.putAll({for (var b in fresh) b.id: b});
      return fresh;
    } catch (e) {
      log('Branches background sync failed: $e');
      return _branchBox.values.toList(); // fall back to stale cache
    }
  }

  // ── YEARS ─────────────────────────────────────────────────────────────────

  Future<List<Year>> getYears() async {
    if (_yearBox.isNotEmpty) {
      _refreshYears();
      return _yearBox.values.toList();
    }
    return _refreshYears();
  }

  Future<List<Year>> _refreshYears() async {
    try {
      final raw = await _rest.getList('years?select=id,name');
      final fresh = raw.map((e) => Year.fromJson(e as Map<String, dynamic>)).toList();
      await _yearBox.clear();
      await _yearBox.putAll({for (var y in fresh) y.id: y});
      return fresh;
    } catch (e) {
      log('Years background sync failed: $e');
      return _yearBox.values.toList();
    }
  }

  // ── SUBJECTS BY SEMESTER ──────────────────────────────────────────────────

  Future<List<Subject>> getSubjectsBySemester({
    required String branchId,
    required int semester,
  }) async {
    final cacheKey = '${branchId}_$semester';
    final cached = _subjectBox.values
        .where((s) => s.key.toString().startsWith(cacheKey))
        .toList();

    if (cached.isNotEmpty) {
      _refreshSubjects(branchId: branchId, semester: semester, cacheKey: cacheKey);
      return _sortByPriority(cached);
    }
    return _refreshSubjects(branchId: branchId, semester: semester, cacheKey: cacheKey);
  }

  Future<List<Subject>> _refreshSubjects({
    required String branchId,
    required int semester,
    required String cacheKey,
  }) async {
    try {
      // Resolve effective branch for first-year mapper (keeps existing logic)
      final effectiveBranchId = await FirstYearBranchMapper.getEffectiveBranchId(
        supabase: _supabase,
        originalBranchId: branchId,
        semester: semester,
      );

      final raw = await _rest.getList(
        'branch_subjects'
        '?branch_id=eq.$effectiveBranchId'
        '&semester=eq.$semester'
        '&select=subjects(id,name,code,pyq_drive_link,notes_drive_link,'
        'course_outcome_link,priority,subject_credit,subject_type)',
      );

      final subjects = (raw)
          .where((e) => e['subjects'] != null)
          .map((e) => Subject.fromJson(e['subjects'] as Map<String, dynamic>))
          .toList();

      // Apply user customizations (still uses SDK because it needs auth.uid())
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final customRes = await _supabase
            .from('user_subject_customizations')
            .select('action, subjects(id, name, code, pyq_drive_link, '
                'notes_drive_link, course_outcome_link, priority, subject_credit, subject_type)')
            .eq('user_id', userId)
            .eq('branch_id', effectiveBranchId)
            .eq('semester', semester);

        for (final custom in customRes as List) {
          final action = custom['action'] as String;
          final subjectData = custom['subjects'];
          if (subjectData == null) continue;
          final subject = Subject.fromJson(subjectData as Map<String, dynamic>);
          if (action == 'add' && !subjects.any((s) => s.id == subject.id)) {
            subjects.add(subject);
          } else if (action == 'remove') {
            subjects.removeWhere((s) => s.id == subject.id);
          }
        }
      }

      // Persist to cache (key = cacheKey + subject.id for uniqueness)
      for (final oldKey in _subjectBox.keys.where((k) => k.toString().startsWith(cacheKey)).toList()) {
        await _subjectBox.delete(oldKey);
      }
      await _subjectBox.putAll({for (var s in subjects) '${cacheKey}_${s.id}': s});

      return _sortByPriority(subjects);
    } catch (e) {
      log('Subjects background sync failed: $e');
      return _sortByPriority(
        _subjectBox.values.where((s) => s.key.toString().startsWith(cacheKey)).toList(),
      );
    }
  }

  List<Subject> _sortByPriority(List<Subject> subjects) {
    subjects.sort((a, b) {
      if (a.priority == null && b.priority == null) return 0;
      if (a.priority == null) return 1;
      if (b.priority == null) return -1;
      return a.priority!.compareTo(b.priority!);
    });
    return subjects;
  }

  // ── GLOBAL SUBJECTS BY SEMESTER ──────────────────────────────────────────

  Future<List<Subject>> getGlobalSubjectsBySemester({
    required String branchId,
    required int semester,
  }) async {
    final cacheKey = 'global_${branchId}_$semester';
    final cached = _subjectBox.values
        .where((s) => s.key.toString().startsWith(cacheKey))
        .toList();

    if (cached.isNotEmpty) {
      _refreshGlobalSubjects(branchId: branchId, semester: semester, cacheKey: cacheKey);
      return _sortByPriority(cached);
    }
    return _refreshGlobalSubjects(branchId: branchId, semester: semester, cacheKey: cacheKey);
  }

  Future<List<Subject>> _refreshGlobalSubjects({
    required String branchId,
    required int semester,
    required String cacheKey,
  }) async {
    try {
      final effectiveBranchId = await FirstYearBranchMapper.getEffectiveBranchId(
        supabase: _supabase,
        originalBranchId: branchId,
        semester: semester,
      );

      final raw = await _rest.getList(
        'branch_subjects'
        '?branch_id=eq.$effectiveBranchId'
        '&semester=eq.$semester'
        '&select=subjects(id,name,code,pyq_drive_link,notes_drive_link,'
        'course_outcome_link,priority,subject_credit,subject_type)',
      );

      final subjects = (raw)
          .where((e) => e['subjects'] != null)
          .map((e) => Subject.fromJson(e['subjects'] as Map<String, dynamic>))
          .toList();

      for (final oldKey in _subjectBox.keys.where((k) => k.toString().startsWith(cacheKey)).toList()) {
        await _subjectBox.delete(oldKey);
      }
      await _subjectBox.putAll({for (var s in subjects) '${cacheKey}_${s.id}': s});

      return _sortByPriority(subjects);
    } catch (e) {
      log('Global subjects background sync failed: $e');
      return _sortByPriority(
        _subjectBox.values.where((s) => s.key.toString().startsWith(cacheKey)).toList(),
      );
    }
  }

  // ── ALL SUBJECTS (for Skulk / search) ────────────────────────────────────

  Future<List<Subject>> getAllSubjects() async {
    const cacheKey = 'all';
    final cached = _subjectBox.values
        .where((s) => s.key.toString().startsWith(cacheKey))
        .toList();

    if (cached.isNotEmpty) {
      _refreshAllSubjects();
      return _sortByPriority(cached);
    }
    return _refreshAllSubjects();
  }

  Future<List<Subject>> _refreshAllSubjects() async {
    try {
      final raw = await _rest.getList(
        'subjects?select=id,name,code,pyq_drive_link,notes_drive_link,'
        'course_outcome_link,priority,subject_credit,subject_type',
      );
      final subjects = raw.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
      for (final oldKey in _subjectBox.keys.where((k) => k.toString().startsWith('all')).toList()) {
        await _subjectBox.delete(oldKey);
      }
      await _subjectBox.putAll({for (var s in subjects) 'all_${s.id}': s});
      return _sortByPriority(subjects);
    } catch (e) {
      log('AllSubjects background sync failed: $e');
      return _sortByPriority(
        _subjectBox.values.where((s) => s.key.toString().startsWith('all')).toList(),
      );
    }
  }

  // ── OTHER HELPER METHODS ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getStudentByRollNo(String rollNo) async {
    try {
      final res = await _rest.getList('students?roll_no=eq.$rollNo&select=*');
      if (res.isNotEmpty) {
        return res.first as Map<String, dynamic>;
      }
      return null;
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
    final effectiveBranchId = await FirstYearBranchMapper.getEffectiveBranchId(
      supabase: _supabase,
      originalBranchId: branchId,
      semester: semester,
    );

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    // Check if there is an existing customization for this subject
    final existingCustom = await _supabase
        .from('user_subject_customizations')
        .select()
        .eq('user_id', userId)
        .eq('branch_id', effectiveBranchId)
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
        .eq('branch_id', effectiveBranchId)
        .eq('semester', semester)
        .eq('subject_id', subjectId)
        .maybeSingle();

    if (existingGlobal != null) {
      // If it exists in the global syllabus, we insert a 'remove' customization to hide it for this user
      await _supabase.from('user_subject_customizations').insert({
        'user_id': userId,
        'branch_id': effectiveBranchId,
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
    final effectiveBranchId = await FirstYearBranchMapper.getEffectiveBranchId(
      supabase: _supabase,
      originalBranchId: branchId,
      semester: semester,
    );

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    // Check if there is an existing customization for this subject
    final existingCustom = await _supabase
        .from('user_subject_customizations')
        .select()
        .eq('user_id', userId)
        .eq('branch_id', effectiveBranchId)
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
        .eq('branch_id', effectiveBranchId)
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
      'branch_id': effectiveBranchId,
      'semester': semester,
      'subject_id': subjectId,
      'action': 'add',
    });
  }
}
