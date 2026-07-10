import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/features/pyqs/presentation/widgets/drive_explorer_tab.dart';

class GlobalResourcesScreen extends StatelessWidget {
  const GlobalResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Global Resource',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: const SafeArea(
        child: DriveExplorerTab(
          title: 'Global Resource',
          driveLink: 'https://drive.google.com/drive/folders/1Ugm0zGR4A1d-mZPjCemNmxV7IsPK7Skg',
          preventDownload: true,
        ),
      ),
    );
  }
}
