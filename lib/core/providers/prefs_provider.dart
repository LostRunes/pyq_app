import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SelectedBranchIdNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getString('selected_branch_id') ?? '';
  }

  Future<void> setBranchId(String value) async {
    state = value;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('selected_branch_id', value);
  }
}

final selectedBranchIdProvider =
    NotifierProvider<SelectedBranchIdNotifier, String>(
      SelectedBranchIdNotifier.new,
    );

class SelectedSemesterNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getInt('selected_semester') ?? 1;
  }

  Future<void> setSemester(int value) async {
    state = value;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt('selected_semester', value);
  }
}

final selectedSemesterProvider =
    NotifierProvider<SelectedSemesterNotifier, int>(
      SelectedSemesterNotifier.new,
    );
