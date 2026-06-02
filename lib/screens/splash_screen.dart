import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Perform startup authentication & smart routing checks after 2 seconds
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // Not logged in -> Go to Login Screen
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      try {
        final userId = session.user.id;
        // Check if user profile exists on Supabase 2
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('username')
            .eq('id', userId)
            .maybeSingle();

        if (!mounted) return;

        if (profile == null) {
          // Logged in but has no profile -> Go to login screen and prompt username
          Navigator.pushReplacementNamed(
            context,
            '/login',
            arguments: {'showUsernameDialog': true},
          );
          return;
        }

        // Profile exists, perform email mapping
        final email = session.user.email ?? '';
        final kiitRegex = RegExp(r'^(\d+)@kiit\.ac\.in$', caseSensitive: false);
        final match = kiitRegex.firstMatch(email);

        if (match != null) {
          final rollNo = match.group(1)!;
          // Search student on Supabase 1 via SupabaseService
          final studentService = ref.read(supabaseServiceProvider);
          final student = await studentService.getStudentByRollNo(rollNo);

          if (student != null && mounted) {
            final batch = student['batch']?.toString() ?? '';
            final section = student['section']?.toString() ?? '';

            final branchId = await studentService.getBranchIdFromSection(section);
            final semester = _getSemesterFromBatch(batch);

            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/subjects',
                arguments: {
                  'branchId': branchId,
                  'semester': semester,
                },
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Splash routing failed, falling back: $e');
      }

      // Default fallback -> selection screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/selection');
      }
    });
  }



  int _getSemesterFromBatch(String batch) {
    final match = RegExp(r'\d+').firstMatch(batch);
    if (match == null) return 1;
    final batchNum = int.parse(match.group(0)!);

    final month = DateTime.now().month;
    final isEvenSemester = month >= 1 && month <= 6;

    if (isEvenSemester) {
      // In even semester (Jan-June), upcoming batch N is finishing semester (2 * N - 2)
      return (2 * batchNum - 2).clamp(1, 8);
    } else {
      // In odd semester (July-Dec), batch N starts semester (2 * N - 1)
      return (2 * batchNum - 1).clamp(1, 8);
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background color: Use a warm cream that blends perfectly with the logo
    // If dark mode is active, use the dark background for a comfortable transition
    final backgroundColor = isDark ? const Color(0xFF1E110A) : const Color(0xFFFAF4EA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/images/FocusFox_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              Text(
                'Focus Fox',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isDark ? const Color(0xFFFBF8F5) : const Color(0xFF3D2F27),
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'STUDY • FOCUS • GROW',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.0,
                  color: isDark ? const Color(0xFFBCA99C) : const Color(0xFF7A6456),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
