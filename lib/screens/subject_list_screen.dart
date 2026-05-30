import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../models/subject.dart';
import '../models/branch.dart';

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

class _SubjectListScreenState extends ConsumerState<SubjectListScreen>
    with SingleTickerProviderStateMixin {
  late int _currentSemester;
  late String _currentBranchId;
  int _currentIndex = 0; // 0: Subjects, 1: Syllabus, 2: Dashboard, 3: Settings

  // For dummy upload notes form
  int? _uploadSemester;
  Subject? _uploadSubject;

  // Animation controller for fluid water bubble wobble
  late AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _currentSemester = widget.semester;
    _currentBranchId = widget.branchId;
    _uploadSemester = _currentSemester;

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 110,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications. 🔔')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Search feature coming soon! 🔍'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REVA',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Image.asset(
                'assets/images/reva_logo.png',
                height: 38,
                width: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildSubjectsPage(context),
          _buildSemestersPage(context),
          _buildDashboardPage(context),
          _buildSettingsPage(context),
        ],
      ),
      bottomNavigationBar: _buildCuteBottomNavBar(context),
    );
  }

  Widget _buildCuteBottomNavBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tabWidth = size.width / 4;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Lighter theme-matching palette in light mode, original warm deep palette in dark mode
    final Color orangeBgStart = isDark
        ? const Color(0xFF421E0B)
        : const Color.fromARGB(255, 251, 203, 158);
    final Color orangeBgEnd = isDark
        ? const Color(0xFF240E04)
        : const Color.fromARGB(255, 238, 206, 154);
    final Color orangeActive = isDark
        ? const Color(0xFFFFB74D)
        : const Color.fromARGB(255, 90, 41, 0);
    final Color orangeActiveBg = isDark
        ? const Color(0x22FFB74D)
        : const Color(0x1AD37D3E);
    final Color orangeInactive = isDark
        ? const Color.fromARGB(255, 231, 171, 133)
        : const Color(0x997A6456);
    final Color shadowColor = isDark
        ? Colors.black38
        : Colors.black.withOpacity(0.06);

    return Container(
      height: 80 + bottomPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [orangeBgStart, orangeBgEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated Fluid Water Drop behind the active tab
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            left: (_currentIndex * tabWidth) + (tabWidth - 84) / 2,
            top: 13,
            child: AnimatedBuilder(
              animation: _wobbleController,
              builder: (context, child) {
                final val = _wobbleController.value;
                // Undulating organic border radius simulating a liquid water droplet
                return Container(
                  width: 84,
                  height: 52,
                  decoration: BoxDecoration(
                    color: orangeActiveBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26 + 12 * val),
                      topRight: Radius.circular(34 - 12 * val),
                      bottomLeft: Radius.circular(30 - 10 * val),
                      bottomRight: Radius.circular(28 + 10 * val),
                    ),
                    border: Border.all(
                      color: orangeActive.withOpacity(0.25 * val),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
          // Nav Bar Items
          Positioned.fill(
            bottom: bottomPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavBarItem(
                  0,
                  Icons.book_rounded,
                  'Subjects',
                  orangeActive,
                  orangeInactive,
                ),
                _buildNavBarItem(
                  1,
                  Icons.collections_bookmark_rounded,
                  'Syllabus',
                  orangeActive,
                  orangeInactive,
                ),
                _buildNavBarItem(
                  2,
                  Icons.leaderboard_rounded,
                  'Dashboard',
                  orangeActive,
                  orangeInactive,
                ),
                _buildNavBarItem(
                  3,
                  Icons.settings_rounded,
                  'Settings',
                  orangeActive,
                  orangeInactive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsPage(BuildContext context) {
    final subjectsAsync = ref.watch(
      subjectsProvider((branchId: _currentBranchId, semester: _currentSemester)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(
          subjectsProvider((
            branchId: _currentBranchId,
            semester: _currentSemester,
          )).future,
        );
      },
      child: subjectsAsync.when(
        data: (subjects) => ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: subjects.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subjects',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
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
                  ],
                ),
              );
            }

            final subject = subjects[i - 1];
            final isIconLeft = (i - 1) % 2 == 0;

            final iconWidget = Container(
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
            );

            final textWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Code: ${subject.code}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            );

            /*
            // Old Version: Standard layout (Icon then Text, with trailing arrow)
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/subject_dashboard',
                    arguments: {'subject': subject},
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Code: ${subject.code}',
                              style: Theme.of(context).textTheme.bodyMedium
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
            */

            // New Version: Alternating layout (Odd: Icon -> Text; Even: Text -> Icon) without trailing arrow
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/subject_dashboard',
                    arguments: {'subject': subject},
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
                      if (isIconLeft) ...[
                        iconWidget,
                        const SizedBox(width: 20),
                      ],
                      Expanded(
                        child: textWidget,
                      ),
                      if (!isIconLeft) ...[
                        const SizedBox(width: 20),
                        iconWidget,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error: $e\n\nPull down to retry',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPage(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(
      subjectsProvider((
        branchId: _currentBranchId,
        semester: _uploadSemester ?? _currentSemester,
      )),
    );

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
          Text(
            'Dashboard',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          // Upload Notes Panel
          Container(
            padding: const EdgeInsets.all(20),
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
                      Icons.cloud_upload_rounded,
                      color: theme.colorScheme.primary,
                    ),
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
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                        items: List.generate(8, (i) => i + 1)
                            .map(
                              (sem) => DropdownMenuItem(
                                value: sem,
                                child: Text('S$sem'),
                              ),
                            )
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
                          if (_uploadSubject != null &&
                              !subs.any((s) => s.id == _uploadSubject!.id)) {
                            _uploadSubject = null;
                          }
                          return DropdownButtonFormField<Subject>(
                            value: _uploadSubject,
                            isExpanded: true,
                            hint: Text(
                              'Select Subject',
                              style: GoogleFonts.outfit(fontSize: 12),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                            ),
                            items: subs
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
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
                          child: const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => DropdownButtonFormField<Subject>(
                          isExpanded: true,
                          items: const [],
                          onChanged: null,
                          decoration: const InputDecoration(
                            labelText: 'Error loading subjects',
                          ),
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
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Notes uploaded for ${_uploadSubject!.name}! Points +50 ✨',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
          Text(
            'Settings',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  items: List.generate(8, (i) => i + 1)
                      .map(
                        (sem) => DropdownMenuItem(
                          value: sem,
                          child: Text('Semester $sem'),
                        ),
                      )
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
                const SizedBox(height: 20),
                Text(
                  'Change Selected Branch',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                ref.watch(branchesProvider).when(
                  data: (branches) {
                    final currentBranch = branches.firstWhere(
                      (b) => b.id == _currentBranchId,
                      orElse: () => branches.first,
                    );
                    return DropdownButtonFormField<Branch>(
                      value: currentBranch,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      items: branches
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(
                                b.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (branch) {
                        if (branch != null) {
                          setState(() {
                            _currentBranchId = branch.id;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to ${branch.name}! ⚡'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text(
                    'Error loading branches: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
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
                    Icon(
                      Icons.favorite_rounded,
                      color: theme.colorScheme.tertiary,
                      size: 20,
                    ),
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

  Widget _buildSemestersPage(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      itemCount: 9, // index 0 is header, 1-8 are semesters
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syllabus',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore subjects across all semesters.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final sem = index;
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
            _SemesterSubjectsList(branchId: _currentBranchId, semester: sem),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SemesterSubjectsList extends ConsumerWidget {
  final String branchId;
  final int semester;

  const _SemesterSubjectsList({required this.branchId, required this.semester});

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
                subtitle: Text(
                  'Code: ${subject.code}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
                /*
                // Old Version: Had a trailing arrow
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                */

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
