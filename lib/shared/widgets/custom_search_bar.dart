import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final double height;
  final EdgeInsetsGeometry? margin;

  const CustomSearchBar({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.autofocus = false,
    this.height = 44,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(fontSize: 14),
        autofocus: autofocus,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}
