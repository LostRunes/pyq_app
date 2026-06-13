import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';

class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  int? _selectedSyllabusSemester; // null means 'All Semesters'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentBranchId = ref.watch(selectedBranchIdProvider);

    final filterSemesters = [null, 1, 2, 3, 4, 5, 6, 7, 8];

    // Determine what to display: single semester or all semesters
    final List<int> displayedSemesters = _selectedSyllabusSemester == null
        ? List.generate(8, (i) => i + 1)
        : [_selectedSyllabusSemester!];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Syllabus',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                ),
              )
            : null,
        child: RefreshIndicator(
          onRefresh: () async {
            final futures = displayedSemesters.map(
              (sem) => ref.refresh(
                subjectsProvider((
                  branchId: currentBranchId,
                  semester: sem,
                )).future,
              ),
            );
            await Future.wait(futures);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            itemCount: 1 + displayedSemesters.length, // index 0 is header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Explore subjects across semesters.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Horizontal scrollable semester filter pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Row(
                          children: filterSemesters.map((sem) {
                            final isSelected = _selectedSyllabusSemester == sem;
                            final label = sem == null
                                ? 'All Semesters'
                                : 'Semester $sem';

                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSyllabusSemester = sem;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                            ? theme.colorScheme.primary
                                            : const Color(0xFF7D4B26))
                                        : (isDark
                                            ? theme.colorScheme.surface
                                                .withOpacity(0.4)
                                            : const Color(0xFFFFF7ED)),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : (isDark
                                              ? theme.colorScheme.primary
                                                  .withOpacity(0.15)
                                              : const Color(0xFFF6DDB7)),
                                      width: 1.2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: isDark
                                                  ? theme.colorScheme.primary
                                                      .withOpacity(0.25)
                                                  : const Color(
                                                      0xFF7D4B26,
                                                    ).withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    label,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? (isDark
                                              ? theme.colorScheme.onPrimary
                                              : Colors.white)
                                          : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF7D4B26)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final sem = displayedSemesters[index - 1];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'Semester $sem',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  _SyllabusSemesterSubjectsList(
                    branchId: currentBranchId,
                    semester: sem,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SyllabusSemesterSubjectsList extends ConsumerWidget {
  final String branchId;
  final int semester;

  const _SyllabusSemesterSubjectsList({
    required this.branchId,
    required this.semester,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(
      subjectsProvider((branchId: branchId, semester: semester)),
    );

    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Text(
              'No subjects found for this semester.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: subjects.length,
          itemBuilder: (context, idx) {
            final subject = subjects[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.15),
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.book_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                title: Text(
                  subject.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code: ${subject.code}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (subject.subjectCredit != null ||
                        subject.subjectType != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (subject.subjectCredit != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${subject.subjectCredit} Cr',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            if (subject.subjectType != null)
                              const SizedBox(width: 6),
                          ],
                          if (subject.subjectType != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    subject.subjectType!.toLowerCase() == 'core'
                                        ? Colors.redAccent.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subject.subjectType!.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: subject.subjectType!.toLowerCase() ==
                                          'core'
                                      ? Colors.redAccent
                                      : Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/subject_dashboard',
                    arguments: {'subject': subject},
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Text(
          'Error: $e',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }
}
