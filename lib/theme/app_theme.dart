import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Richer Earthy Palette (Light Mode)
  static const Color primaryColor = Color(
    0xFFD37D3E,
  ); // Deep Toffee / Burnt Sienna
  static const Color secondaryColor = Color(0xFF8BA682); // Muted Sage
  static const Color accentColor = Color(0xFFE08E9D); // Deeper Rose

  static const Color lightBg = Color(0xFFFBEAD0); // Warm Sand / Parchment
  static const Color lightSurface = Color(0xFFFFF8EE); // Warm Cream
  static const Color lightText = Color(0xFF3D2F27); // Dark Coffee
  static const Color lightSubText = Color(0xFF7A6456); // Muted Earth Brown

  // Magical Violet / Starry Night Palette (Dark Mode)
  static const Color darkPrimary = Color(0xFFC0A6FF); // Soft glowing lavender
  static const Color darkSecondary = Color(0xFF8A7CB5); // Muted lavender
  static const Color darkAccent = Color(0xFFFFBCE8); // Pastel pink/rose
  static const Color darkBg = Color(
    0xFF171330,
  ); // Deep magical night sky purple
  static const Color darkSurface = Color(0xFF251E4E); // Deep violet surface
  static const Color darkText = Color(0xFFFFFFFF); // Pure white
  static const Color darkSubText = Color(0xFFB8AEDB); // Lavender muted subtext

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final primary = isDark ? darkPrimary : primaryColor;
    final secondary = isDark ? darkSecondary : secondaryColor;
    final tertiary = isDark ? darkAccent : accentColor;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: isDark ? darkSurface : lightSurface,
        background: isDark ? darkBg : lightBg,
        onPrimary: isDark ? const Color(0xFF171330) : Colors.white,
        onSurface: isDark ? darkText : lightText,
        onBackground: isDark ? darkText : lightText,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? darkBg : lightBg,
      cardTheme: CardThemeData(
        color: isDark ? darkSurface.withOpacity(0.85) : lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: isDark ? darkText : lightText,
        ),
        displaySmall: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: isDark ? darkText : lightText,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          color: isDark ? darkText : lightText,
        ),
        titleMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: isDark ? darkText : lightText,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: isDark ? darkText : lightText,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: isDark ? darkSubText : lightSubText,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: isDark ? darkText : lightText,
        ),
        iconTheme: IconThemeData(color: isDark ? darkText : lightText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? const Color(0xFF171330) : Colors.white,
          minimumSize: const Size.fromHeight(64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 2,
          shadowColor: primary.withOpacity(0.3),
          textStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface.withOpacity(0.7) : lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
      ),
    );
  }
}
