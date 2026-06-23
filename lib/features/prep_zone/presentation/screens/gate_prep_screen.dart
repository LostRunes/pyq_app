import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GatePrepScreen extends StatelessWidget {
  const GatePrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subjects = [
      {'name': 'Engineering Mathematics', 'weight': '13-15%', 'color': const Color(0xFF6366F1)},
      {'name': 'Digital Logic & COA', 'weight': '8-10%', 'color': const Color(0xFF10B981)},
      {'name': 'Data Structures & Algorithms', 'weight': '12-15%', 'color': const Color(0xFF3B82F6)},
      {'name': 'Theory of Computation & CD', 'weight': '8-10%', 'color': const Color(0xFF8B5CF6)},
      {'name': 'Operating Systems', 'weight': '8-10%', 'color': const Color(0xFFEC4899)},
      {'name': 'Database Management Systems', 'weight': '6-8%', 'color': const Color(0xFFF59E0B)},
      {'name': 'Computer Networks', 'weight': '8-10%', 'color': const Color(0xFF14B8A6)},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GATE Prep Hub',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ace the GATE Exam',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'High-weightage subjects, syllabus breakdowns, and test papers.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              // Quick Mock Test Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7D4B26), Color(0xFFD37D3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7D4B26).withOpacity(0.3),
                      blurRadius: 16,
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
                            'GATE Mock Challenge',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Simulate full exam conditions (65 Qs, 180 Mins)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7D4B26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Starting Mock Test simulator... 📝')),
                        );
                      },
                      child: Text(
                        'Start Now',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Subject Weightage Breakdown',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final sub = subjects[index];
                  final color = sub['color'] as Color;
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
                        sub['name'] as String,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sub['weight'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening syllabus/study guide for ${sub['name']}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
