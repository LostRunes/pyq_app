import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/utils/first_year_branch_mapper.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final List<Map<String, dynamic>> branchesData;
  FakeSupabaseClient(this.branchesData);

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'branches') {
      return FakeSupabaseQueryBuilder(branchesData);
    }
    throw UnimplementedError();
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> data;
  FakeSupabaseQueryBuilder(this.data);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestFilterBuilder(data);
  }
}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  FakePostgrestFilterBuilder(this.data);

  @override
  Future<U> then<U>(FutureOr<U> Function(List<Map<String, dynamic>> value) onValue, {Function? onError}) {
    return Future.value(data).then(onValue, onError: onError);
  }
}

void main() {
  group('FirstYearBranchMapper tests', () {
    test('Should return original branchId if semester is not 1 or 2', () async {
      final fakeSupabase = FakeSupabaseClient([]);
      
      final result3 = await FirstYearBranchMapper.getEffectiveBranchId(
        supabase: fakeSupabase,
        originalBranchId: 'some-original-branch-id',
        semester: 3,
      );
      expect(result3, 'some-original-branch-id');

      final result8 = await FirstYearBranchMapper.getEffectiveBranchId(
        supabase: fakeSupabase,
        originalBranchId: 'some-original-branch-id',
        semester: 8,
      );
      expect(result8, 'some-original-branch-id');
    });

    test('Should map to CSE branchId if semester is 1 or 2', () async {
      final mockBranches = [
        {'id': 'other-id', 'name': 'ECSC'},
        {'id': 'cse-uuid', 'name': 'CSE'},
        {'id': 'csse-id', 'name': 'CSSE'},
      ];
      final fakeSupabase = FakeSupabaseClient(mockBranches);

      final result1 = await FirstYearBranchMapper.getEffectiveBranchId(
        supabase: fakeSupabase,
        originalBranchId: 'other-id',
        semester: 1,
      );
      expect(result1, 'cse-uuid');

      final result2 = await FirstYearBranchMapper.getEffectiveBranchId(
        supabase: fakeSupabase,
        originalBranchId: 'other-id',
        semester: 2,
      );
      expect(result2, 'cse-uuid');
    });
  });
}
