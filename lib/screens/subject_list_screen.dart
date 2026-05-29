import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../models/subject.dart';

class SubjectListScreen extends ConsumerStatefulWidget {
  final String branchId;
  final int semester;
  const SubjectListScreen({
    super.key,
    required this.branchId,
    required this.semester,
  });

  @override
  ConsumerState<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  late int _currentSemester;
  int _currentIndex = 0; // 0: Subjects, 1: Dashboard, 2: Settings

  // For dummy upload notes form
  int? _uploadSemester;
  Subject? _uploadSubject;

  @override
  void initState() {
    super.initState();
    _currentSemester = widget.semester;
    _uploadSemester = _currentSemester;
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Subjects';
      case 1:
        return 'Dashboard';
      case 2:
        return 'Settings';
      default:
        return 'Subjects';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        automaticallyImplyLeading: _currentIndex == 0, // Back button only on Subjects tab
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildSubjectsPage(context),
          _buildDashboardPage(context),
          _buildSettingsPage(context),
        ],
      ),
      bottomNavigationBar: _buildCuteBottomNavBar(context),
    );
  }

  Widget _buildCuteBottomNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 28, top: 8),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: primaryColor.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(0, Icons.book_rounded, 'Subjects'),
            _buildNavBarItem(1, Icons.leaderboard_rounded, 'Dashboard'),
            _buildNavBarItem(2, Icons.settings_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? primaryColor : theme.colorScheme.onSurface.withOpacity(0.5),
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsPage(BuildContext context) {
    final subjectsAsync = ref.watch(
      subjectsProvider((branchId: widget.branchId, semester: _currentSemester)),
    );

    return subjectsAsync.when(
      data: (subjects) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: subjects.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your path!',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a subject to begin.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: Image.asset('assets/images/panda.png'),
                  ),
                ],
              ),
            );
          }

          final subject = subjects[i - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/subject_dashboard',
                  arguments: {
                    'subject': subject,
                  },
                );
              },
              borderRadius: BorderRadius.circular(32),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.book_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Code: ${subject.code}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDashboardPage(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(subjectsProvider((branchId: widget.branchId, semester: _uploadSemester ?? _currentSemester)));

    final List<Map<String, dynamic>> leaderboard = [
      {'rank': 1, 'roll': '22CS30024', 'points': 1480},
      {'rank': 2, 'roll': '22CS10012', 'points': 1320},
      {'rank': 3, 'roll': '22CS30045', 'points': 1250},
      {'rank': 4, 'roll': '22CS30002', 'points': 1100},
      {'rank': 5, 'roll': '22CS10089', 'points': 980},
      {'rank': 6, 'roll': '22CS30018', 'points': 920},
      {'rank': 7, 'roll': '22CS10044', 'points': 850},
      {'rank': 8, 'roll': '22CS30037', 'points': 810},
      {'rank': 9, 'roll': '22CS10056', 'points': 740},
      {'rank': 10, 'roll': '22CS30090', 'points': 690},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload Notes Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
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
                    Icon(Icons.cloud_upload_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Study Notes 📚',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _uploadSemester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                        items: List.generate(8, (i) => i + 1)
                            .map((sem) => DropdownMenuItem(value: sem, child: Text('S$sem')))
                            .toList(),
                        onChanged: (sem) {
                          setState(() {
                            _uploadSemester = sem;
                            _uploadSubject = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: subjectsAsync.when(
                        data: (subs) {
                          if (_uploadSubject != null && !subs.any((s) => s.id == _uploadSubject!.id)) {
                            _uploadSubject = null;
                          }
                          return DropdownButtonFormField<Subject>(
                            value: _uploadSubject,
                            hint: Text('Select Subject', style: GoogleFonts.outfit(fontSize: 12)),
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 12),
                            items: subs
                                .map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (sub) {
                              setState(() {
                                _uploadSubject = sub;
                              });
                            },
                          );
                        },
                        loading: () => Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, __) => DropdownButtonFormField<Subject>(
                          items: const [],
                          onChanged: null,
                          decoration: const InputDecoration(labelText: 'Error loading subjects'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _uploadSubject == null
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Notes uploaded for ${_uploadSubject!.name}! Points +50 ✨',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Upload Notes'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  'Top Contributors 🏆',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...leaderboard.map((item) {
            final rank = item['rank'] as int;
            Color rankBgColor = Colors.transparent;
            Color rankTextColor = theme.colorScheme.onSurface.withOpacity(0.5);

            if (rank == 1) {
              rankBgColor = Colors.amber.shade100;
              rankTextColor = Colors.amber.shade900;
            } else if (rank == 2) {
              rankBgColor = Colors.grey.shade200;
              rankTextColor = Colors.grey.shade800;
            } else if (rank == 3) {
              rankBgColor = Colors.orange.shade100;
              rankTextColor = Colors.orange.shade900;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rankBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: rankTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    item['roll'],
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item['points']} pts',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsPage(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Preferences ⚙️',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Change Selected Semester',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _currentSemester,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: List.generate(8, (i) => i + 1)
                      .map((sem) => DropdownMenuItem(value: sem, child: Text('Semester $sem')))
                      .toList(),
                  onChanged: (sem) {
                    if (sem != null) {
                      setState(() {
                        _currentSemester = sem;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to Semester $sem! ⚡'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/panda.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PYQ App',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Version 1.0.0 (Royace Build)',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Your companion for previous year questions (PYQs), notes, importance-score tracking, and AI-powered solutions. Designed to make university exams a breeze. ✨',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, color: theme.colorScheme.tertiary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Made with Love for Students',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
