import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/models/branch.dart';
import '../../data/models/year.dart';
import '../../../pyqs/data/models/subject.dart';

final branchesProvider = FutureProvider<List<Branch>>((ref) {
  final repository = ref.watch(subjectsRepositoryProvider);
  return repository.getBranches();
});

final yearsProvider = FutureProvider<List<Year>>((ref) {
  final repository = ref.watch(subjectsRepositoryProvider);
  return repository.getYears();
});

final subjectsProvider =
    FutureProvider.family<List<Subject>, ({String branchId, int semester})>((
      ref,
      arg,
    ) {
      final repository = ref.watch(subjectsRepositoryProvider);
      return repository.getSubjectsBySemester(
        branchId: arg.branchId,
        semester: arg.semester,
      );
    });

final globalSubjectsProvider =
    FutureProvider.family<List<Subject>, ({String branchId, int semester})>((
      ref,
      arg,
    ) {
      final repository = ref.watch(subjectsRepositoryProvider);
      return repository.getGlobalSubjectsBySemester(
        branchId: arg.branchId,
        semester: arg.semester,
      );
    });

final allSubjectsProvider = FutureProvider<List<Subject>>((ref) {
  final repository = ref.watch(subjectsRepositoryProvider);
  return repository.getAllSubjects();
});

class SubjectsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateSearch(String query) => state = query;
}

final subjectsSearchProvider = NotifierProvider<SubjectsSearchNotifier, String>(
  SubjectsSearchNotifier.new,
);

class SubjectTitleAnimationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setShown(bool value) => state = value;
}

final hasShownSubjectTitleAnimationProvider = NotifierProvider<SubjectTitleAnimationNotifier, bool>(
  SubjectTitleAnimationNotifier.new,
);
