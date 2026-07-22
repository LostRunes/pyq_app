import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import '../providers/gate_providers.dart';

class GatePrepScreen extends ConsumerStatefulWidget {
  const GatePrepScreen({super.key});

  @override
  ConsumerState<GatePrepScreen> createState() => _GatePrepScreenState();
}

class _GatePrepScreenState extends ConsumerState<GatePrepScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Color> _colors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF14B8A6), // Teal
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subjectsAsync = ref.watch(gateSubjectsProvider);
    final papersAsync = ref.watch(gatePapersProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0C20) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF171330) : theme.appBarTheme.backgroundColor,
        title: Text(
          'GATE Prep Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: isDark ? Colors.white : Colors.black87,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Subject-wise Practice'),
            Tab(text: 'Past Exam Papers'),
          ],
        ),
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
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            // Subjects Tab
            subjectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (subjects) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(gateSubjectsProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice by Subject',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Strengthen your core subject concepts with targeted GATE questions.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            final String id = subject['id'] ?? '';
                            final String name = subject['name'] ?? 'Subject';
                            final String code = subject['code'] ?? '';
                            final color = _colors[index % _colors.length];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: color.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(0.1),
                                  child: Icon(Icons.menu_book_rounded, color: color),
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  'Subject Code: $code',
                                  style: GoogleFonts.outfit(fontSize: 11),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded, color: color),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/gate_topics',
                                    arguments: {
                                      'subjectId': id,
                                      'subjectName': name,
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Past Papers Tab
            papersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (papers) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(gatePapersProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Full Papers',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solve past years exam papers to experience real exam patterns.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: papers.length,
                          itemBuilder: (context, index) {
                            final paper = papers[index];
                            final String id = paper['id'] ?? '';
                            final String exam = paper['exam'] ?? 'GATE';
                            final int year = paper['year'] ?? 2026;
                            final int? setNumber = paper['set_number'];
                            final color = _colors[(index + 3) % _colors.length];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: color.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(0.1),
                                  child: Icon(Icons.assignment_rounded, color: color),
                                ),
                                title: Text(
                                  '$exam ($year)',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  setNumber != null ? 'Set $setNumber' : 'Full Exam Paper',
                                  style: GoogleFonts.outfit(fontSize: 11),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded, color: color),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/gate_questions',
                                    arguments: {
                                      'paperId': id,
                                      'title': '$exam - $year' + (setNumber != null ? ' (Set $setNumber)' : ''),
                                      'type': 'paper',
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
