import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/core/providers.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers/theme_provider.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';
import 'package:focus_fox/features/subjects/data/models/branch.dart';
import 'package:focus_fox/services/push_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _tempSemester;
  String? _tempBranchId;

  // Mock toggle values for premium feel
  bool _pushNotifications = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _tempSemester = ref.read(selectedSemesterProvider);
    _tempBranchId = ref.read(selectedBranchIdProvider);
    _pushNotifications =
        ref.read(sharedPrefsProvider).getBool('push_notifications') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final branchesAsync = ref.watch(branchesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                ),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF7ED),
                    const Color(0xFFFFF1F2).withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // Preferences Group
                _buildSectionHeader(
                  context,
                  isDark,
                  'Preferences',
                  Icons.tune_rounded,
                ),
                const SizedBox(height: 12),
                _buildPreferencesCard(context, isDark, branchesAsync),

                const SizedBox(height: 24),

                // Styling & System Group
                _buildSectionHeader(
                  context,
                  isDark,
                  'App Settings',
                  Icons.settings_brightness_rounded,
                ),
                const SizedBox(height: 12),
                _buildAppSettingsCard(context, isDark, themeMode),

                const SizedBox(height: 24),

                // Information & Version Card
                _buildInfoCard(context, isDark),
                const SizedBox(height: 24),

                // Support & Feedback Group
                _buildSectionHeader(
                  context,
                  isDark,
                  'Support & Feedback',
                  Icons.help_outline_rounded,
                ),
                const SizedBox(height: 12),
                _buildContactCard(context, isDark),
                const SizedBox(height: 24),

                // Danger Zone — Logout
                _buildSectionHeader(
                  context,
                  isDark,
                  'Account',
                  Icons.manage_accounts_rounded,
                ),
                const SizedBox(height: 12),
                _buildLogoutCard(context, isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(
    BuildContext context,
    bool isDark,
    AsyncValue<List<Branch>> branchesAsync,
  ) {
    final cardColor = isDark
        ? const Color(0xFF251E4E).withOpacity(0.85)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Change Semester Dropdown
          Text(
            'Academic Semester',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _tempSemester ?? 4, // Default mock or active sem
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            items: List.generate(8, (i) => i + 1)
                .map(
                  (sem) => DropdownMenuItem(
                    value: sem,
                    child: Text(
                      'Semester $sem',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (sem) {
              if (sem != null) {
                setState(() {
                  _tempSemester = sem;
                });
                ref.read(selectedSemesterProvider.notifier).setSemester(sem);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched view to Semester $sem! ⚡'),
                    duration: const Duration(milliseconds: 800),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // Change Branch Dropdown
          Text(
            'Branch / Specialization',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          branchesAsync.when(
            data: (branches) {
              final activeBranchId = _tempBranchId ?? branches.first.id;
              final selectedBranch = branches.firstWhere(
                (b) => b.id == activeBranchId,
                orElse: () => branches.first,
              );
              return DropdownButtonFormField<Branch>(
                initialValue: selectedBranch,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                items: branches
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(
                          b.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (branch) {
                  if (branch != null) {
                    setState(() {
                      _tempBranchId = branch.id;
                    });
                    ref
                        .read(selectedBranchIdProvider.notifier)
                        .setBranchId(branch.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched view to ${branch.name}! ⚡'),
                        duration: const Duration(milliseconds: 800),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Text(
              'Error loading branches: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard(
    BuildContext context,
    bool isDark,
    ThemeMode themeMode,
  ) {
    final theme = Theme.of(context);
    final cardColor = isDark
        ? const Color(0xFF251E4E).withOpacity(0.85)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Theme Toggle Row
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDark
                  ? const Color(0xFFC0A6FF)
                  : theme.colorScheme.primary,
            ),
            title: Text(
              'Dark Mode Theme',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              isDark
                  ? 'Starry night palette active'
                  : 'Warm cream palette active',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            trailing: Switch.adaptive(
              value: themeMode == ThemeMode.dark,
              activeColor: const Color(0xFFC0A6FF),
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggle();
              },
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          // Push Notifications Row
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: Icon(
              Icons.notifications_active_outlined,
              color: isDark
                  ? const Color(0xFFC0A6FF)
                  : theme.colorScheme.primary,
            ),
            title: Text(
              'Exam Notifications',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Get alerted on newly added PYQ sheets',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            trailing: Switch.adaptive(
              value: _pushNotifications,
              activeColor: const Color(0xFFC0A6FF),
              onChanged: (val) async {
                setState(() {
                  _pushNotifications = val;
                });
                final prefs = ref.read(sharedPrefsProvider);
                await prefs.setBool('push_notifications', val);
                if (val) {
                  await PushNotificationService.registerDeviceToken();
                } else {
                  await PushNotificationService.deleteDeviceToken();
                }
              },
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          // Haptics Feedback Row
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: Icon(
              Icons.vibration_rounded,
              color: isDark
                  ? const Color(0xFFC0A6FF)
                  : theme.colorScheme.primary,
            ),
            title: Text(
              'Micro-Haptics',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Vibrate on tab shifts & page changes',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            trailing: Switch.adaptive(
              value: _hapticFeedback,
              activeColor: const Color(0xFFC0A6FF),
              onChanged: (val) {
                setState(() {
                  _hapticFeedback = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cardColor = isDark
        ? const Color(0xFF251E4E).withOpacity(0.85)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/panda.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PYQ Companion',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF3D2F27),
            ),
          ),
          Text(
            'Version 1.2.0',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Your ultimate study companion for exam preparation. Access solved previous year questions (PYQs), track topic importance, and grind in focus rooms.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: theme.colorScheme.tertiary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Made with Love for Students',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1A3C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'You will be signed out of your Google account. You can sign back in anytime.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Capture navigator BEFORE await — context is not safe across async gaps
      final navigator = Navigator.of(context);
      await signOutCompletely(ref: ref);
      // Navigate to login, clearing the entire stack so user can't press Back
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildLogoutCard(BuildContext context, bool isDark) {
    final cardColor = isDark
        ? const Color(0xFF251E4E).withOpacity(0.85)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.red.withOpacity(0.3)
              : Colors.red.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: Colors.redAccent,
            size: 22,
          ),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Colors.redAccent,
          ),
        ),
        subtitle: Text(
          'Sign out from your Google account',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.redAccent.withOpacity(0.7),
        ),
        onTap: _confirmSignOut,
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'focusfox.admin@gmail.com',
      query: 'subject=Focus%20Fox%20Support%20%26%20Feedback',
    );
    try {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client.'),
          ),
        );
      }
    }
  }

  Widget _buildContactCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cardColor = isDark
        ? const Color(0xFF251E4E).withOpacity(0.85)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Support',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'focusfox.admin@gmail.com',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Have a question, found a bug, or want to suggest a new feature? We'd love to hear from you! Reach out to our support team directly.",
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3D357F) : theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _launchEmail,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              'Send Email',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
