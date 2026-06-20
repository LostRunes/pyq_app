import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showLoginRequiredDialog(BuildContext context, String actionText) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1A3C) : Colors.white,
        title: Row(
          children: [
            Text(
              'Join Focus Fox! 🦊',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'You need to log in to $actionText. Sign in with Google to connect with college peers and access all features.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899), // Pink accent color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: Text(
              'Log In',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    },
  );
}
