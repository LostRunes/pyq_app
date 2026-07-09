import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/subjects/data/models/branch.dart';

class FirstYearBranchMapper {
  static String? _cachedCseBranchId;

  /// Returns the effective branch ID. For semesters 1 and 2 (First Year), it maps
  /// all branch IDs to the CSE branch ID. Otherwise, it returns the original branch ID.
  static Future<String> getEffectiveBranchId({
    required SupabaseClient supabase,
    required String originalBranchId,
    required int semester,
  }) async {
    if (semester == 1 || semester == 2) {
      if (_cachedCseBranchId != null) {
        return _cachedCseBranchId!;
      }
      try {
        final res = await supabase.from('branches').select();
        final branches = (res as List).map((e) => Branch.fromJson(e)).toList();
        final cseBranch = branches.firstWhere(
          (b) => b.name.toUpperCase() == 'CSE',
          orElse: () => branches.firstWhere(
            (b) => b.name.toUpperCase().contains('CS'),
            orElse: () => branches.first,
          ),
        );
        _cachedCseBranchId = cseBranch.id;
        return _cachedCseBranchId!;
      } catch (_) {
        // Fallback to original if anything fails
        return originalBranchId;
      }
    }
    return originalBranchId;
  }
}
