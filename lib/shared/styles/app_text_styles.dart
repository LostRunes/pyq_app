import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle title(BuildContext context) {
    return GoogleFonts.outfit(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    return GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 3.0,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );
  }

  static TextStyle cardTitle(BuildContext context) {
    return GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle cardSubtitle(BuildContext context) {
    return GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
      height: 1.5,
    );
  }

  static TextStyle button(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontWeight: FontWeight.w800,
      fontSize: 16,
      color: color,
    );
  }

  static TextStyle popupTitle(BuildContext context) {
    return GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle popupSubtitle(BuildContext context) {
    return GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
      height: 1.4,
    );
  }

  static TextStyle label(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: color ?? Theme.of(context).colorScheme.primary,
      letterSpacing: 1.5,
    );
  }

  static TextStyle input(BuildContext context) {
    return GoogleFonts.outfit(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
  }

  static TextStyle helperText({required Color color}) {
    return GoogleFonts.outfit(
      fontSize: 11,
      color: color,
      fontWeight: FontWeight.bold,
    );
  }
}
