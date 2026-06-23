import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/styles/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/mascot_avatar_selector.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool showUsernameDialog;
  const LoginScreen({super.key, this.showUsernameDialog = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _showUsernamePopup = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  String _selectedAvatarPath = 'assets/images/pikachu.png';

  Timer? _debounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameUnique;
  String _usernameError = '';
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    if (widget.showUsernameDialog) {
      setState(() {
        _showUsernamePopup = true;
      });
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
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
      final repository = ref.read(authRepositoryProvider);
      final profile = await repository.handlePostLogin(user);

      setState(() {
        _isLoading = false;
      });

      if (profile == null) {
        setState(() {
          _showUsernamePopup = true;
        });
      } else {
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
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.getRedirectResult(email);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          result.routeName,
          arguments: result.arguments,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Redirection check failed: $e');
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
        final repository = ref.read(authRepositoryProvider);
        final isUnique = await repository.checkUsernameUnique(cleanValue);

        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameUnique = isUnique;
            if (!isUnique) {
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

  void _generateUsername() {
    final repository = ref.read(authRepositoryProvider);
    final newUsername = repository.generateCoolUsername();
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

      final repository = ref.read(authRepositoryProvider);
      await repository.submitUsername(
        userId: user.id,
        username: username,
        displayName: displayName.isEmpty ? null : displayName,
        avatarUrl: _selectedAvatarPath,
      );

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
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.helperText(color: Colors.white),
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
          style: AppTextStyles.helperText(color: Colors.white),
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
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: bgGradient),
          ),
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      style: AppTextStyles.title(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'STUDY • FOCUS • GROW',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle(context),
                    ),
                    const SizedBox(height: 60),
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
                            style: AppTextStyles.cardTitle(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Access your previous year questions, solved answers, and connect with your college peers.',
                            style: AppTextStyles.cardSubtitle(context),
                          ),
                          const SizedBox(height: 32),
                          GoogleSignInButton(
                            isLoading: _isLoading,
                            onPressed: _signInWithGoogle,
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
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 35,
                          offset: Offset(0, 15),
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
                          style: AppTextStyles.popupTitle(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Express yourself! Claim your unique handle, add a display name, and select a mascot avatar.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.popupSubtitle(context),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'CHOOSE YOUR STUDY MASCOT',
                          style: AppTextStyles.label(context),
                        ),
                        const SizedBox(height: 10),
                        MascotAvatarSelector(
                          selectedAvatarPath: _selectedAvatarPath,
                          onSelected: (path) {
                            setState(() {
                              _selectedAvatarPath = path;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'UNIQUE USERNAME (REQUIRED)',
                              style: AppTextStyles.label(context),
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
                                style: AppTextStyles.label(
                                  context,
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
                        AppTextField(
                          controller: _usernameController,
                          onChanged: _onUsernameChanged,
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
                        const SizedBox(height: 6),
                        if (_isCheckingUsername)
                          Text(
                            'Checking availability...',
                            style: AppTextStyles.helperText(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else if (_isUsernameUnique == true)
                          Text(
                            'Username is available! ✨',
                            style: AppTextStyles.helperText(color: Colors.green),
                          )
                        else if (_usernameError.isNotEmpty)
                          Text(
                            _usernameError,
                            style: AppTextStyles.helperText(
                              color: Colors.redAccent,
                            ),
                          ),
                        const SizedBox(height: 18),
                        Text(
                          'DISPLAY NAME (OPTIONAL)',
                          style: AppTextStyles.label(context),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _displayNameController,
                          hintText: 'e.g. Alex Mercer',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 32),
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
                                  style: AppTextStyles.button(
                                    context,
                                    color: isDark ? const Color(0xFF171330) : Colors.white,
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
