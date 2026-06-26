import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // URL launched successfully
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color orangeBgStart = isDark
        ? const Color(0xFF251E4E)
        : const Color.fromARGB(255, 251, 203, 158);
    final Color orangeBgEnd = isDark
        ? const Color(0xFF15112E)
        : const Color.fromARGB(255, 238, 206, 154);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141414)
          : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'About App',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Top Row: Title (Left) & Logo (Right) - padded to be closer to middle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOCUS',
                        style: GoogleFonts.outfit(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'FOX',
                        style: GoogleFonts.outfit(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                          color: const Color(0xFFFF9F0A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9F0A).withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/FocusFox_icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // App Description
            Text(
              'Focus Fox is your ultimate engineering companion designed to help you prepare for core engineering exams. Keep track of previous year questions, practice DSA patterns, collaborate on doubt feeds, and leverage customized utilities all in one place to streamline your learning journey.',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                height: 1.45,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 36),
            // Heading: FOUNDERS/ DEVELOPERS
            Text(
              'FOUNDERS/ DEVELOPERS',
              style: GoogleFonts.outfit(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 20),
            // Developer 1: Yogisha Rani
            _buildDeveloperCard(
              context: context,
              name: 'Yogisha Rani',
              role: 'Founder & Lead Developer',
              avatarAsset: 'assets/images/pikachu.png',
              linkedin: 'https://www.linkedin.com/in/yogisha-rani-1382a7381/',
              github: 'https://github.com/LostRunes',
              instagram: 'https://www.instagram.com/lostpresence_2/#',
              isDark: isDark,
              orangeBgStart: orangeBgStart,
              orangeBgEnd: orangeBgEnd,
            ),
            const SizedBox(height: 20),
            // Developer 2: Abinash Mohanty
            _buildDeveloperCard(
              context: context,
              name: 'Abinash Mohanty',
              role: 'Co-Founder & Core Architect',
              avatarAsset: 'assets/images/panda.png',
              linkedin: 'https://www.linkedin.com/in/abinash-mohanty-/',
              github: 'https://github.com/abinashmohanty8059',
              instagram: 'https://www.instagram.com/_.royace._/',
              isDark: isDark,
              orangeBgStart: orangeBgStart,
              orangeBgEnd: orangeBgEnd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard({
    required BuildContext context,
    required String name,
    required String role,
    required String avatarAsset,
    required String linkedin,
    required String github,
    required String instagram,
    required bool isDark,
    required Color orangeBgStart,
    required Color orangeBgEnd,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFFF9F0A).withOpacity(0.2)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage(avatarAsset),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [orangeBgStart, orangeBgEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    context: context,
                    label: 'LinkedIn',
                    icon: Icons.link_rounded,
                    onPressed: () => _launchURL(linkedin),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildSocialButton(
                    context: context,
                    label: 'GitHub',
                    icon: Icons.code_rounded,
                    onPressed: () => _launchURL(github),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildSocialButton(
                    context: context,
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    onPressed: () => _launchURL(instagram),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
