import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool showUsernameDialog;
  const LoginScreen({super.key, this.showUsernameDialog = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _showUsernamePopup = false;

  // Onboarding controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  String _selectedAvatarPath = 'assets/images/pikachu.png'; // Default avatar

  Timer? _debounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameUnique;
  String _usernameError = '';
  late StreamSubscription<AuthState> _authSubscription;

  // Native Google Sign-In — shows in-app account picker, no browser redirect
  late final GoogleSignIn _googleSignIn;

  // Cute mascot avatars list
  final List<Map<String, String>> _mascots = [
    {'name': 'Pikachu', 'path': 'assets/images/pikachu.png'},
    {'name': 'Fox', 'path': 'assets/images/lil_fox.png'},
    {'name': 'Panda', 'path': 'assets/images/panda.png'},
    {'name': 'Cat', 'path': 'assets/images/cat.png'},
    {'name': 'Octopus', 'path': 'assets/images/lil_octopus.png'},
    {'name': 'Owl', 'path': 'assets/images/owl.png'},
    {'name': 'Polar Bear', 'path': 'assets/images/polar_bearr.png'},
    {'name': 'Raccoon', 'path': 'assets/images/raccoon.png'},
    {'name': 'Toothless', 'path': 'assets/images/toothless.png'},
    {'name': 'Shark', 'path': 'assets/images/sleepy-shark.png'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize Google Sign-In with the Web OAuth Client ID from .env
    // This enables the native in-app account picker popup
    _googleSignIn = GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      scopes: [
        'email',
        'profile',
      ],
    );

    if (widget.showUsernameDialog) {
      setState(() {
        _showUsernamePopup = true;
      });
    }

    // Listen for Supabase auth state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        setState(() {
          _isLoading = false;
        });
        await _handlePostLogin(session.user);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _usernameController.dispose();
    _displayNameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _handlePostLogin(User user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user profile already exists on Supabase 2
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _isLoading = false;
      });

      if (profile == null) {
        // Show the unique username prompt
        setState(() {
          _showUsernamePopup = true;
        });
      } else {
        // Profile exists, perform smart redirection based on email
        await _checkEmailAndRedirect(user.email ?? '');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Auth check failed: $e');
    }
  }

  Future<void> _checkEmailAndRedirect(String email) async {
    final kiitRegex = RegExp(r'^(\d+)@kiit\.ac\.in$', caseSensitive: false);
    final match = kiitRegex.firstMatch(email);

    if (match != null) {
      final rollNo = match.group(1)!;
      setState(() {
        _isLoading = true;
      });

      // Search student details on Supabase 1 via SupabaseService
      final studentService = ref.read(supabaseServiceProvider);
      final student = await studentService.getStudentByRollNo(rollNo);

      setState(() {
        _isLoading = false;
      });

      if (student != null) {
        final batch = student['batch']?.toString() ?? '';
        final section = student['section']?.toString() ?? '';

        final branchId = await studentService.getBranchIdFromSection(section);
        final semester = _getSemesterFromBatch(batch);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/main_navigation',
            arguments: {'branchId': branchId, 'semester': semester},
          );
        }
        return;
      }
    }

    // Redirect to welcome back selection page if not a KIIT student or not found in DB
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/selection');
    }
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

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cleanValue = value.trim();
    if (cleanValue.length < 3) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameUnique = null;
        _usernameError = 'Username must be at least 3 characters';
      });
      return;
    }

    // Regexp pattern for safe usernames
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(cleanValue)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameUnique = null;
        _usernameError = 'Only letters, numbers, and underscores allowed';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = '';
      _isUsernameUnique = null;
    });

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final res = await Supabase.instance.client
            .from('user_profiles')
            .select('id')
            .eq('username', cleanValue)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameUnique = res == null;
            if (res != null) {
              _usernameError = 'Username is already taken';
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameUnique = null;
            _usernameError = 'Error checking username: $e';
          });
        }
      }
    });
  }

  String _generateCoolUsername() {
    final adjectives = [
      'smart',
      'study',
      'focus',
      'epic',
      'cyber',
      'nerdy',
      'sleepy',
      'shadow',
      'swift',
      'clever',
      'cosmic',
      'pixel',
      'bright',
      'super',
      'quick',
      'bold',
      'alpha',
      'omega',
      'zen',
      'active',
      'prime',
      'stellar',
      'happy',
      'coding',
    ];
    final nouns = [
      'fox',
      'panda',
      'pikachu',
      'cat',
      'octopus',
      'owl',
      'bear',
      'raccoon',
      'shark',
      'dragon',
      'scholar',
      'coder',
      'genius',
      'learner',
      'champion',
      'wizard',
    ];
    final rand = Random();
    final adj = adjectives[rand.nextInt(adjectives.length)];
    final noun = nouns[rand.nextInt(nouns.length)];
    final num = rand.nextInt(900) + 100; // 3 digit number: 100-999

    return '${adj}_${noun}_$num';
  }

  void _generateUsername() {
    final newUsername = _generateCoolUsername();
    _usernameController.text = newUsername;
    _onUsernameChanged(newUsername);
  }

  Future<void> _submitUsername() async {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    if (username.isEmpty || _isUsernameUnique != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No logged in user found');

      // Insert profile on Supabase 2
      await Supabase.instance.client.from('user_profiles').insert({
        'id': user.id,
        'username': username,
        'display_name': displayName.isEmpty ? null : displayName,
        'avatar_url': _selectedAvatarPath,
      });

      setState(() {
        _isLoading = false;
        _showUsernamePopup = false;
      });

      _showSuccessSnackBar('Profile created! Welcome to Skulk! 🦊');
      await _checkEmailAndRedirect(user.email ?? '');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to save profile: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Silently try to get existing sign-in session first (avoids deadlock
      // caused by calling signOut() while a previous signIn() is still
      // resolving on the plugin's internal thread).
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      // If no cached session, show the account picker
      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        // User dismissed the picker
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the auth tokens from the selected Google account
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(
          'Google Sign In failed: could not retrieve ID token. '
          'Check that GOOGLE_WEB_CLIENT_ID in .env matches your Supabase Google provider.',
        );
        return;
      }

      // Pass the Google ID token to Supabase — no browser involved
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      // Auth state listener above handles routing after successful sign-in
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Deadlock error from google_sign_in plugin: a previous sign-in attempt
      // is still resolving. Disconnect fully and ask user to try again.
      final errStr = e.toString();
      if (errStr.contains('deadlock') || errStr.contains('main thread')) {
        try {
          await _googleSignIn.disconnect();
        } catch (_) {
          // Ignore disconnect errors — we just want to clear state
        }
        _showErrorSnackBar(
          'Sign-in initializing, please tap "Continue with Google" again.',
        );
      } else {
        _showErrorSnackBar('Google Sign In failed: $e');
      }
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF171330), Color(0xFF0F0B22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFFBEAD0), Color(0xFFFFF8EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: bgGradient),
          ),

          // Floating ambient shape graphics
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.08),
              ),
            ),
          ),

          // Main Login Page UI
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mascot Icon (Focus Fox Logo)
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.05,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/focus_fox_nobg.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Focus Fox',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'STUDY • FOCUS • GROW',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Authentication card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.25 : 0.05,
                            ),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Access your previous year questions, solved answers, and connect with your college peers.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.65,
                              ),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Google OAuth trigger
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF251E4E)
                                  : const Color(0xFFFFF4E6),
                              foregroundColor: theme.colorScheme.onSurface,
                              elevation: 0,
                              side: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.2,
                                ),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google_logo.png',
                                        height: 24,
                                        width: 24,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.g_mobiledata_rounded,
                                                  size: 28,
                                                  color: Colors.redAccent,
                                                ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Escapable Onboarding Profile Setup Pop-up Dialog
          if (_showUsernamePopup)
            Container(
              color: Colors.black.withOpacity(0.7),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 35,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Setup Your Skulk Profile 🦊',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Express yourself! Claim your unique handle, add a display name, and select a mascot avatar.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.65,
                            ),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Interactive Scrolling Mascot Avatar Selector
                        Text(
                          'CHOOSE YOUR STUDY MASCOT',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 86,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _mascots.length,
                            itemBuilder: (context, index) {
                              final mascot = _mascots[index];
                              final isSelected =
                                  _selectedAvatarPath == mascot['path'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAvatarPath = mascot['path']!;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 14),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: CircleAvatar(
                                    radius: 34,
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E193C)
                                        : Colors.amber.shade50.withOpacity(0.3),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Image.asset(
                                        mascot['path']!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'UNIQUE USERNAME (REQUIRED)',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _generateUsername,
                              icon: Icon(
                                Icons.casino_outlined,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                'Generate',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          onChanged: _onUsernameChanged,
                          decoration: InputDecoration(
                            hintText: 'e.g. smart_owl',
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              size: 18,
                            ),
                            suffixIcon: _isCheckingUsername
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : (_isUsernameUnique == true
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green,
                                        )
                                      : (_isUsernameUnique == false
                                            ? const Icon(
                                                Icons.error_rounded,
                                                color: Colors.redAccent,
                                              )
                                            : null)),
                          ),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Verification Helper text
                        if (_isCheckingUsername)
                          Text(
                            'Checking availability...',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (_isUsernameUnique == true)
                          Text(
                            'Username is available! ✨',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (_usernameError.isNotEmpty)
                          Text(
                            _usernameError,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        const SizedBox(height: 18),

                        // Optional Display Name Field
                        Text(
                          'DISPLAY NAME (OPTIONAL)',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Alex Mercer',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                            ),
                          ),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Confirm Submit Button
                        ElevatedButton(
                          onPressed: (_isUsernameUnique == true && !_isLoading)
                              ? _submitUsername
                              : null,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Confirm & Enter Focus Fox',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
