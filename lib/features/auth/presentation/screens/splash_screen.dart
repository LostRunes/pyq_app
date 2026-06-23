import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for the animation to finish
    await Future.delayed(const Duration(milliseconds: 2000));

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final userId = session.user.id;

    // Run inside safety try-catch block
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select()
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
        final isKiit = kiitRegex.hasMatch(email);

        if (isKiit) {
          final redirect = await ref.read(authRepositoryProvider).getRedirectResult(email);
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              redirect.routeName,
              arguments: redirect.arguments,
            );
          }
          return;
        } else {
          // Non-KIIT user: Check SharedPreferences for previously saved branch & semester
          final prefs = ref.read(sharedPrefsProvider);
          final savedBranchId = prefs.getString('selected_branch_id');
          final savedSemester = prefs.getInt('selected_semester');

          if (savedBranchId != null &&
              savedBranchId.isNotEmpty &&
              savedSemester != null) {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/main_navigation',
                arguments: {
                  'branchId': savedBranchId,
                  'semester': savedSemester,
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
    final backgroundColor = isDark
        ? const Color(0xFF1E110A)
        : const Color(0xFFFAF4EA);

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
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                  color: isDark
                      ? const Color(0xFFFBF8F5)
                      : const Color(0xFF3D2F27),
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
                  color: isDark
                      ? const Color(0xFFBCA99C)
                      : const Color(0xFF7A6456),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
