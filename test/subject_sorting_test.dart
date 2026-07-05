import 'package:flutter_test/flutter_test.dart';
import 'package:focus_fox/features/pyqs/data/models/subject.dart';

void main() {
  test('Subject sorting: core first, then highest credit descending', () {
    final s1 = Subject(id: '1', name: 'Core high credit', code: 'C1', subjectType: 'Core', subjectCredit: 4);
    final s2 = Subject(id: '2', name: 'Core low credit', code: 'C2', subjectType: 'core', subjectCredit: 2);
    final s3 = Subject(id: '3', name: 'Elective high credit', code: 'E1', subjectType: 'Elective', subjectCredit: 4);
    final s4 = Subject(id: '4', name: 'Elective low credit', code: 'E2', subjectType: 'elective', subjectCredit: 3);
    final s5 = Subject(id: '5', name: 'Null type high credit', code: 'N1', subjectType: null, subjectCredit: 5);

    final subjects = [s4, s3, s2, s5, s1];

    // Apply the sorting logic from subjects_page.dart
    subjects.sort((a, b) {
      final aIsCore = a.subjectType?.toLowerCase() == 'core';
      final bIsCore = b.subjectType?.toLowerCase() == 'core';
      if (aIsCore != bIsCore) return aIsCore ? -1 : 1;
      final aCredits = a.subjectCredit ?? 0;
      final bCredits = b.subjectCredit ?? 0;
      return bCredits.compareTo(aCredits);
    });

    // Expected order:
    // 1. Core high credit (Core, 4)
    // 2. Core low credit (Core, 2)
    // 3. Null type high credit (null, 5) -- since null is not 'core', it goes below core, sorted by credits (5)
    // 4. Elective high credit (Elective, 4)
    // 5. Elective low credit (Elective, 3)
    expect(subjects[0].id, '1'); // Core high credit
    expect(subjects[1].id, '2'); // Core low credit
    expect(subjects[2].id, '5'); // Null type high credit (non-core 5 credits)
    expect(subjects[3].id, '3'); // Elective high credit (non-core 4 credits)
    expect(subjects[4].id, '4'); // Elective low credit (non-core 3 credits)
  });
}
