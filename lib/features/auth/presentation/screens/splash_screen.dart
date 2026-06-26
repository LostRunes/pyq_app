import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers/auth_provider.dart';
import 'package:focus_fox/services/push_notification_service.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

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

  Future<({String routeName, Object? arguments})> _determineDestination() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return (routeName: '/login', arguments: null);
    }

    // Register push notification token
    unawaited(PushNotificationService.registerDeviceToken());

    final userId = session.user.id;
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      return (routeName: '/login', arguments: {'showUsernameDialog': true});
    }

    // Profile exists, perform email mapping
    final email = session.user.email ?? '';
    final kiitRegex = RegExp(r'^(\d+)@kiit\.ac\.in$', caseSensitive: false);
    final isKiit = kiitRegex.hasMatch(email);

    if (isKiit) {
      final redirect = await ref.read(authRepositoryProvider).getRedirectResult(email);
      return (routeName: redirect.routeName, arguments: redirect.arguments);
    } else {
      // Non-KIIT user: Check SharedPreferences for previously saved branch & semester
      final prefs = ref.read(sharedPrefsProvider);
      final savedBranchId = prefs.getString('selected_branch_id');
      final savedSemester = prefs.getInt('selected_semester');

      if (savedBranchId != null &&
          savedBranchId.isNotEmpty &&
          savedSemester != null) {
        return (routeName: '/main_navigation', arguments: {
          'branchId': savedBranchId,
          'semester': savedSemester,
        });
      }
    }

    return (routeName: '/selection', arguments: null);
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final authCheckFuture = _determineDestination();
    final animationDelayFuture = Future.delayed(const Duration(milliseconds: 1800));

    try {
      final results = await Future.wait([
        authCheckFuture,
        animationDelayFuture,
      ]);

      final dest = results[0] as ({String routeName, Object? arguments});

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          dest.routeName,
          arguments: dest.arguments,
        );
      }
    } catch (e) {
      debugPrint('Splash routing failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to connect. Please check your network connection.';
          _isLoading = false;
        });
      }
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _checkAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9F0A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ] else if (_isLoading) ...[
                const SizedBox(height: 32),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9F0A)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
