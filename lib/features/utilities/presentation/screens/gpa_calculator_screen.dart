import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';

class GpaCalculatorScreen extends ConsumerStatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  ConsumerState<GpaCalculatorScreen> createState() =>
      _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends ConsumerState<GpaCalculatorScreen> {
  int _calculatorTab = 0; // 0: SGPA, 1: CGPA
  bool _isInitialized = false;

  final List<Map<String, dynamic>> _sgpaCourses = [
    {'name': 'Subject 1', 'credits': 4.0, 'gradePoint': 10.0},
    {'name': 'Subject 2', 'credits': 3.0, 'gradePoint': 9.0},
    {'name': 'Subject 3', 'credits': 3.0, 'gradePoint': 8.0},
  ];

  final List<Map<String, dynamic>> _cgpaSemesters = [
    {'semester': 1, 'sgpa': 9.0},
  ];

  String _getMascotForGpa(double gpa) {
    if (gpa >= 9.0) {
      return 'assets/images/focus_fox_nobg.png';
    } else if (gpa >= 8.0) {
      return 'assets/images/panda.png';
    } else if (gpa >= 7.0) {
      return 'assets/images/polar_bearr.png';
    } else if (gpa > 0.0) {
      return 'assets/images/sad_raccoon.png';
    } else {
      return 'assets/images/axolot_on_a_phone.png';
    }
  }

  String _getMessageForGpa(double gpa) {
    if (gpa >= 9.0) {
      return 'Outstanding! You are an absolute genius! 🌟';
    } else if (gpa >= 8.0) {
      return 'Amazing score! Keep up the brilliant work! ✌️';
    } else if (gpa >= 7.0) {
      return 'Good going! With a little more push, you will hit 8+! 💪';
    } else if (gpa > 0.0) {
      return 'Keep practicing! Every step brings you closer! 🦊';
    } else {
      return 'Add some courses below to compute your GPA!';
    }
  }

  Widget _buildResultCard(
    double score,
    String type,
    bool isDark,
    ThemeData theme,
  ) {
    final mascot = _getMascotForGpa(score);
    final message = _getMessageForGpa(score);

    final Color cardColor = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.white.withOpacity(0.65);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : theme.colorScheme.primary.withOpacity(0.28);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : theme.colorScheme.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CALCULATED $type',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black54,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  score.toStringAsFixed(2),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mascot Image from profile
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : theme.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(mascot, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fetch subjects dynamically based on active preferences
    final currentBranchId = ref.watch(selectedBranchIdProvider);
    final currentSemester = ref.watch(selectedSemesterProvider);
    final subjectsAsync = ref.watch(
      subjectsProvider((branchId: currentBranchId, semester: currentSemester)),
    );

    subjectsAsync.whenData((subjects) {
      if (!_isInitialized) {
        _sgpaCourses.clear();
        final coreSubjects = subjects
            .where((s) => s.subjectType?.toLowerCase() == 'core')
            .toList();
        if (coreSubjects.isNotEmpty) {
          for (final s in coreSubjects) {
            _sgpaCourses.add({
              'name': s.name,
              'credits': (s.subjectCredit ?? 3).toDouble(),
              'gradePoint': 9.0, // Pre-fill grade E
            });
          }
        } else {
          _sgpaCourses.addAll([
            {'name': 'Subject 1', 'credits': 4.0, 'gradePoint': 10.0},
            {'name': 'Subject 2', 'credits': 3.0, 'gradePoint': 9.0},
            {'name': 'Subject 3', 'credits': 3.0, 'gradePoint': 8.0},
          ]);
        }
        _isInitialized = true;
        // Trigger state refresh
        if (mounted) setState(() {});
      }
    });

    // Calculate SGPA
    double sgpaPoints = 0;
    double sgpaCredits = 0;
    for (var course in _sgpaCourses) {
      final double credits = (course['credits'] as num?)?.toDouble() ?? 0.0;
      final double gradePoint =
          (course['gradePoint'] as num?)?.toDouble() ?? 0.0;
      sgpaPoints += credits * gradePoint;
      sgpaCredits += credits;
    }
    final double calculatedSGPA = sgpaCredits > 0
        ? sgpaPoints / sgpaCredits
        : 0.0;

    // Calculate CGPA (simple average of semester SGPAs)
    double cgpaPoints = 0;
    int cgpaCount = 0;
    for (var sem in _cgpaSemesters) {
      final double sgpa = (sem['sgpa'] as num?)?.toDouble() ?? 0.0;
      cgpaPoints += sgpa;
      cgpaCount++;
    }
    final double calculatedCGPA = cgpaCount > 0
        ? cgpaPoints / cgpaCount
        : 0.0;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0C20)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF171330)
            : theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GPA Calculator',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Banner
                    FadeInSlide(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : theme.colorScheme.primary.withOpacity(0.28),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GPA Calculator 📊',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Calculate your semester SGPA and lifetime CGPA in real-time with your mascots.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 80,
                              width: 80,
                              child: Image.asset(
                                'assets/images/panda_reading_scenario.png',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tab Selector
                    FadeInSlide(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 450),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _calculatorTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: _calculatorTab == 0
                                      ? theme.colorScheme.primary.withOpacity(
                                          0.12,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _calculatorTab == 0
                                        ? theme.colorScheme.primary
                                        : (isDark
                                              ? Colors.white10
                                              : Colors.black12),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'SGPA Calculator',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _calculatorTab == 0
                                        ? theme.colorScheme.primary
                                        : (isDark
                                              ? Colors.white60
                                              : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _calculatorTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: _calculatorTab == 1
                                      ? theme.colorScheme.primary.withOpacity(
                                          0.12,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _calculatorTab == 1
                                        ? theme.colorScheme.primary
                                        : (isDark
                                              ? Colors.white10
                                              : Colors.black12),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'CGPA Calculator',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _calculatorTab == 1
                                        ? theme.colorScheme.primary
                                        : (isDark
                                              ? Colors.white60
                                              : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inputs Card (The "Table" in the middle)
                    FadeInSlide(
                      delay: const Duration(milliseconds: 150),
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : theme.colorScheme.primary.withOpacity(0.28),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_calculatorTab == 0) ...[
                              // SGPA Course rows (Table)
                              ..._sgpaCourses.asMap().entries.map((entry) {
                                final index = entry.key;
                                final course = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.02)
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : theme.colorScheme.primary.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: theme
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue:
                                                  course['name'] as String? ??
                                                  '',
                                              decoration: InputDecoration(
                                                labelText: 'Subject Name',
                                                labelStyle: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                border: InputBorder.none,
                                                hintText:
                                                    'Enter subject name...',
                                              ),
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                              onChanged: (val) {
                                                course['name'] = val;
                                              },
                                            ),
                                          ),
                                          if (_sgpaCourses.length > 1)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _sgpaCourses.removeAt(index);
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                      const Divider(height: 8, thickness: 0.5),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<double>(
                                              isExpanded: true,
                                              value: (course['credits'] as num?)
                                                  ?.toDouble(),
                                              decoration: InputDecoration(
                                                labelText: 'Credits',
                                                labelStyle: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              style: GoogleFonts.outfit(
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontSize: 13,
                                              ),
                                              items: [1.0, 2.0, 3.0, 4.0, 5.0]
                                                  .map(
                                                    (c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Text(
                                                        '${c.toStringAsFixed(1)} Cr',
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                setState(() {
                                                  course['credits'] = val;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonFormField<double>(
                                              isExpanded: true,
                                              value:
                                                  (course['gradePoint'] as num?)
                                                      ?.toDouble(),
                                              decoration: InputDecoration(
                                                labelText: 'Grade',
                                                labelStyle: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              style: GoogleFonts.outfit(
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontSize: 13,
                                              ),
                                              items: [
                                                {'label': 'O (10)', 'val': 10.0},
                                                {'label': 'E (9)', 'val': 9.0},
                                                {'label': 'A (8)', 'val': 8.0},
                                                {'label': 'B (7)', 'val': 7.0},
                                                {'label': 'C (6)', 'val': 6.0},
                                                {'label': 'D (5)', 'val': 5.0},
                                                {'label': 'F (4)', 'val': 4.0},
                                                {'label': 'F (3)', 'val': 3.0},
                                                {'label': 'F (2)', 'val': 2.0},
                                                {'label': 'F (1)', 'val': 1.0},
                                                {'label': 'F (0)', 'val': 0.0},
                                              ]
                                                  .map(
                                                    (g) => DropdownMenuItem(
                                                      value: (g['val'] as num)
                                                          .toDouble(),
                                                      child: Text(
                                                        g['label'] as String,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                setState(() {
                                                  course['gradePoint'] = val;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _sgpaCourses.add({
                                      'name': '',
                                      'credits': 3.0,
                                      'gradePoint': 9.0,
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Course'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // CGPA Semester rows
                              ..._cgpaSemesters.asMap().entries.map((entry) {
                                final index = entry.key;
                                final semester = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.02)
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : theme.colorScheme.primary.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonFormField<int>(
                                              isExpanded: true,
                                              value: semester['semester'] as int?,
                                              decoration: InputDecoration(
                                                labelText: 'Semester',
                                                labelStyle: GoogleFonts.outfit(fontSize: 11),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              items: List.generate(8, (i) => i + 1)
                                                  .map(
                                                    (s) => DropdownMenuItem(
                                                      value: s,
                                                      child: Text('Semester $s'),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                setState(() {
                                                  semester['semester'] = val;
                                                });
                                              },
                                            ),
                                          ),
                                          if (_cgpaSemesters.length > 1)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _cgpaSemesters.removeAt(index);
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                      const Divider(height: 8, thickness: 0.5),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        key: ValueKey('cgpa_sem_${semester['semester']}_$index'),
                                        initialValue: semester['sgpa']?.toString() ?? '',
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Semester SGPA',
                                          labelStyle: GoogleFonts.outfit(fontSize: 11),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          hintText: 'Enter SGPA (e.g. 9.0)',
                                        ),
                                        style: GoogleFonts.outfit(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 13,
                                        ),
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val);
                                          if (parsed != null) {
                                            setState(() {
                                              semester['sgpa'] = parsed;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    final nextSem = _cgpaSemesters.isEmpty
                                        ? 1
                                        : (_cgpaSemesters.last['semester']
                                                  as int) +
                                              1;
                                    _cgpaSemesters.add({
                                      'semester': nextSem > 8 ? 8 : nextSem,
                                      'sgpa': 9.0,
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Semester'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sticky Bottom result card
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF171330).withOpacity(0.9)
                      : Colors.white.withOpacity(0.85),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : theme.colorScheme.primary.withOpacity(0.18),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: _calculatorTab == 0
                    ? _buildResultCard(calculatedSGPA, 'SGPA', isDark, theme)
                    : _buildResultCard(calculatedCGPA, 'CGPA', isDark, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
