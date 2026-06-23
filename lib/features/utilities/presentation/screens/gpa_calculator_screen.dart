import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  int _calculatorTab = 0; // 0: SGPA, 1: CGPA
  final List<Map<String, dynamic>> _sgpaCourses = [
    {'credits': 4.0, 'gradePoint': 10.0},
    {'credits': 3.0, 'gradePoint': 9.0},
    {'credits': 3.0, 'gradePoint': 8.0},
  ];
  final List<Map<String, dynamic>> _cgpaSemesters = [
    {'semester': 1, 'credits': 20.0, 'sgpa': 9.0},
  ];

  Widget _buildSGPAResultCard(ThemeData theme) {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var course in _sgpaCourses) {
      final double credits = (course['credits'] as num?)?.toDouble() ?? 0.0;
      final double gradePoint = (course['gradePoint'] as num?)?.toDouble() ?? 0.0;
      totalPoints += credits * gradePoint;
      totalCredits += credits;
    }
    final double sgpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'SGPA',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            sgpa.toStringAsFixed(2),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCGPAResultCard(ThemeData theme) {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var sem in _cgpaSemesters) {
      final double credits = (sem['credits'] as num?)?.toDouble() ?? 0.0;
      final double sgpa = (sem['sgpa'] as num?)?.toDouble() ?? 0.0;
      totalPoints += credits * sgpa;
      totalCredits += credits;
    }
    final double cgpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'CGPA',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            cgpa.toStringAsFixed(2),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GPA Calculator',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calculate_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'GPA Calculator 📊',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Segmented selector for SGPA / CGPA
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _calculatorTab = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _calculatorTab == 0
                                    ? theme.colorScheme.primary.withOpacity(
                                        0.15,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _calculatorTab == 0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.1,
                                        ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'SGPA',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: _calculatorTab == 0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.6,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _calculatorTab = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _calculatorTab == 1
                                    ? theme.colorScheme.primary.withOpacity(
                                        0.15,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _calculatorTab == 1
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.1,
                                        ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'CGPA',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: _calculatorTab == 1
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.6,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_calculatorTab == 0) ...[
                      // SGPA Calculator
                      ..._sgpaCourses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final course = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<double>(
                                  initialValue: (course['credits'] as num?)?.toDouble(),
                                  decoration: InputDecoration(
                                    labelText: 'Credits',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
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
                                flex: 4,
                                child: DropdownButtonFormField<double>(
                                  initialValue: (course['gradePoint'] as num?)?.toDouble(),
                                  decoration: InputDecoration(
                                    labelText: 'Grade',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                  items:
                                      [
                                            {'label': 'O (10)', 'val': 10.0},
                                            {'label': 'A (9)', 'val': 9.0},
                                            {'label': 'B (8)', 'val': 8.0},
                                            {'label': 'C (7)', 'val': 7.0},
                                            {'label': 'D (6)', 'val': 6.0},
                                            {'label': 'E (5)', 'val': 5.0},
                                            {'label': 'F (0)', 'val': 0.0},
                                          ]
                                          .map(
                                            (g) => DropdownMenuItem(
                                              value: (g['val'] as num).toDouble(),
                                              child: Text(
                                                g['label'] as String,
                                                overflow: TextOverflow.ellipsis,
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
                              if (_sgpaCourses.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _sgpaCourses.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _sgpaCourses.add({
                                  'credits': 3.0,
                                  'gradePoint': 9.0,
                                });
                              });
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Course'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(140, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          _buildSGPAResultCard(theme),
                        ],
                      ),
                    ] else ...[
                      // CGPA Calculator
                      ..._cgpaSemesters.asMap().entries.map((entry) {
                        final index = entry.key;
                        final semester = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  initialValue: semester['semester'] as int?,
                                  decoration: InputDecoration(
                                    labelText: 'Semester',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                  items: List.generate(8, (i) => i + 1)
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text('Sem $s'),
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
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<double>(
                                  initialValue: (semester['credits'] as num?)?.toDouble(),
                                  decoration: InputDecoration(
                                    labelText: 'Credits',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                  items:
                                      [
                                            12.0,
                                            14.0,
                                            16.0,
                                            18.0,
                                            20.0,
                                            22.0,
                                            24.0,
                                            26.0,
                                            28.0,
                                          ]
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(
                                                '${c.toStringAsFixed(0)} Cr',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      semester['credits'] = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<double>(
                                  initialValue: (semester['sgpa'] as num?)?.toDouble(),
                                  decoration: InputDecoration(
                                    labelText: 'SGPA',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                  items:
                                      List.generate(61, (i) => 4.0 + (i * 0.1))
                                          .map(
                                            (g) => DropdownMenuItem(
                                              value: double.parse(
                                                g.toStringAsFixed(1),
                                              ),
                                              child: Text(g.toStringAsFixed(1)),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      semester['sgpa'] = val;
                                    });
                                  },
                                ),
                              ),
                              if (_cgpaSemesters.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _cgpaSemesters.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                final nextSem = _cgpaSemesters.isEmpty
                                    ? 1
                                    : (_cgpaSemesters.last['semester'] as int) +
                                          1;
                                _cgpaSemesters.add({
                                  'semester': nextSem > 8 ? 8 : nextSem,
                                  'sgpa': 9.0,
                                  'credits': 20.0,
                                });
                              });
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Semester'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(160, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          _buildCGPAResultCard(theme),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
