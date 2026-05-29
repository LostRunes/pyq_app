import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Richer Earthy Palette
  static const Color primaryColor = Color(0xFFD37D3E); // Deep Toffee / Burnt Sienna
  static const Color secondaryColor = Color(0xFF8BA682); // Muted Sage
  static const Color accentColor = Color(0xFFE08E9D); // Deeper Rose
  
  static const Color lightBg = Color(0xFFFBEAD0); // Warm Sand / Parchment
  static const Color lightSurface = Color(0xFFFFF8EE); // Warm Cream
  static const Color lightText = Color(0xFF3D2F27); // Dark Coffee
  static const Color lightSubText = Color(0xFF7A6456); // Muted Earth Brown

  static const Color darkBg = Color(0xFF261F1B); // Rich Deep Cocoa
  static const Color darkSurface = Color(0xFF332A25); // Warm Dark Brown
  static const Color darkText = Color(0xFFFBF8F5); // Crisp Off-white
  static const Color darkSubText = Color(0xFFBCA99C);

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: isDark ? darkSurface : lightSurface,
        background: isDark ? darkBg : lightBg,
        onPrimary: Colors.white,
        onSurface: isDark ? darkText : lightText,
        onBackground: isDark ? darkText : lightText,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? darkBg : lightBg,
      cardTheme: CardThemeData(
        color: isDark ? darkSurface : lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.bold, 
          color: isDark ? darkText : lightText
        ),
        displaySmall: GoogleFonts.outfit(
          fontWeight: FontWeight.bold, 
          color: isDark ? darkText : lightText
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w800, 
          color: isDark ? darkText : lightText
        ),
        titleMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, 
          color: isDark ? darkText : lightText
        ),
        bodyLarge: GoogleFonts.outfit(color: isDark ? darkText : lightText, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: isDark ? darkSubText : lightSubText),
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
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : primaryColor.withOpacity(0.2), 
            width: 1.5
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primaryColor, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }
}
