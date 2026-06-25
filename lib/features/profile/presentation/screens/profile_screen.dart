import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/core/providers.dart';
import 'package:focus_fox/core/providers/user_profile_provider.dart';
import 'package:focus_fox/features/subjects/data/models/branch.dart';
import 'package:focus_fox/features/pyqs/presentation/providers/pyq_providers.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';
import 'package:focus_fox/features/profile/presentation/widgets/balloon_donut_chart.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;

  // Dynamic profile states (Supabase 2)
  String _displayName = 'Focus Fox Student';
  String _username = 'focus_fox_user';
  String _avatarPath = 'assets/images/pikachu.png';
  String _email = '';

  // Skulk identity stats
  int _reputation = 0;
  int _doubtsAsked = 0;
  int _solutionsGiven = 0;
  int _acceptedSolutions = 0;

  // Dynamic student record states (Supabase 1)
  String _rollNo = 'External';
  String _branchName = 'General';
  String _semesterVal = 'Onboarding';
  bool _isKiitStudent = false;

  // Mascot List for selection
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
    _fetchProfileAndStudentDetails();
  }

  Future<void> _fetchProfileAndStudentDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _email = user.email ?? '';

      // 1. Fetch profile from Supabase 2
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        setState(() {
          _username = profile['username']?.toString() ?? 'focus_fox_user';
          _displayName =
              profile['display_name']?.toString() ??
              user.userMetadata?['full_name']?.toString() ??
              'Focus Fox Student';
          _avatarPath =
              profile['avatar_url']?.toString() ?? 'assets/images/pikachu.png';
          _reputation = profile['reputation'] as int? ?? 0;
          _doubtsAsked = profile['doubts_asked'] as int? ?? 0;
          _solutionsGiven = profile['solutions_given'] as int? ?? 0;
          _acceptedSolutions = profile['accepted_solutions'] as int? ?? 0;
        });
      }

      // 2. Fetch student details from Supabase 1 using KIIT roll mapping
      final kiitRegex = RegExp(r'^(\d+)@kiit\.ac\.in$', caseSensitive: false);
      final match = kiitRegex.firstMatch(_email);

      if (match != null) {
        final rollNo = match.group(1)!;
        final subjectsRepo = ref.read(subjectsRepositoryProvider);
        final student = await subjectsRepo.getStudentByRollNo(rollNo);

        if (student != null) {
          final batch = student['batch']?.toString() ?? '';
          final section = student['section']?.toString() ?? '';

          // Fetch branches list from Supabase 1 to resolve branch name
          final branches = await subjectsRepo.getBranches();
          final resolvedBranchId = await subjectsRepo.getBranchIdFromSection(
            section,
          );

          final branch = branches.firstWhere(
            (b) => b.id == resolvedBranchId,
            orElse: () => Branch(id: '', name: 'CSE'),
          );

          final mappedSemester = _getSemesterFromBatch(batch);

          setState(() {
            _rollNo = rollNo;
            _branchName = branch.name;
            _semesterVal = 'Semester $mappedSemester';
            _isKiitStudent = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load profile details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _showEditProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        currentUsername: _username,
        currentDisplayName: _displayName,
        currentAvatarPath: _avatarPath,
        mascots: _mascots,
        onSave: (username, displayName, avatarPath) async {
          setState(() {
            _username = username;
            _displayName = displayName;
            _avatarPath = avatarPath;
          });
          ref.invalidate(userProfileProvider);
          _showSuccessSnackBar('Profile updated successfully! ✨');
        },
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
      await signOutCompletely();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trackedTopics = ref.watch(trackedTopicsProvider);
    final topicProgress = ref.watch(progressProvider);
    final completedTopics = trackedTopics.where((id) => topicProgress[id] == true).length;

    final leetcodeProgress = ref.watch(leetCodeProgressProvider);
    final completedLeetcode = leetcodeProgress.values.where((v) => v).length;

    // Subjects segment aggregation
    final allSubjects = ref.watch(allSubjectsProvider).value ?? [];
    final allTopics = ref.watch(allTopicsListProvider).value ?? [];
    final List<Color> subjectColors = [
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Yellow/Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
    ];
    final subjectSegments = <DonutSegment>[];
    for (int i = 0; i < allSubjects.length; i++) {
      final subject = allSubjects[i];
      final subjectTopicIds = allTopics
          .where((t) => t.subjectId == subject.id)
          .map((t) => t.id)
          .toSet();
      final trackedInSubject = trackedTopics.where((id) => subjectTopicIds.contains(id));
      final completedCount = trackedInSubject.where((id) => topicProgress[id] == true).length;
      if (completedCount > 0) {
        subjectSegments.add(
          DonutSegment(
            label: subject.name,
            value: completedCount,
            color: subjectColors[i % subjectColors.length],
          ),
        );
      }
    }

    // Algo & Code segment aggregation
    final leetcodeQuestions = ref.watch(leetcodeQuestionsListProvider).value ?? [];
    final List<Color> algoColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF14B8A6), // Teal
    ];
    final algoTopicNames = [
      'Array',
      'Searching',
      'Recursion',
      'String',
      'Stack',
      'Queue',
      'Linked List',
      'Tree',
      'Graph'
    ];
    final algoSegments = <DonutSegment>[];
    for (int i = 0; i < algoTopicNames.length; i++) {
      final topicName = algoTopicNames[i];
      final questionIds = leetcodeQuestions
          .where((q) => q['parent_topic'] == topicName)
          .map((q) => q['id'].toString())
          .toSet();
      final completedCount = questionIds.where((id) => leetcodeProgress[id] == true).length;
      if (completedCount > 0) {
        algoSegments.add(
          DonutSegment(
            label: topicName,
            value: completedCount,
            color: algoColors[i % algoColors.length],
          ),
        );
      }
    }


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
          'Student Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => _showEditProfileBottomSheet(context),
            ),
          if (!_isLoading)
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: _confirmSignOut,
            ),
          const SizedBox(width: 4),
        ],
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // Dynamic Hero Avatar Card
                      _buildHeroCard(context, isDark),
                      const SizedBox(height: 20),
                      // Skulk Identity Card
                      _buildSkulkCard(context, isDark),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InteractiveBalloonDonut(
                              segments: subjectSegments,
                              totalTarget: trackedTopics.isEmpty ? 1 : trackedTopics.length,
                              title: 'Subjects',
                              subtitle: '$completedTopics / ${trackedTopics.length}',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InteractiveBalloonDonut(
                              segments: algoSegments,
                              totalTarget: 150,
                              title: 'Algo & Code',
                              subtitle: '$completedLeetcode solved',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSkulkCard(BuildContext context, bool isDark) {
    final cardColor = isDark
        ? const Color(0xFF1A1A2E).withOpacity(0.9)
        : Colors.white;

    final stats = [
      {'icon': '🔥', 'label': 'Reputation', 'value': '$_reputation pts'},
      {'icon': '🤔', 'label': 'Doubts Asked', 'value': '$_doubtsAsked'},
      {'icon': '💡', 'label': 'Solutions', 'value': '$_solutionsGiven'},
      {'icon': '✅', 'label': 'Accepted', 'value': '$_acceptedSolutions'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.purple.withOpacity(0.3)
              : Colors.purple.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🦊', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Skulk Identity',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                ),
                child: Text(
                  '@$_username',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.purple[400],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: stats.map((s) {
              return Expanded(
                child: Column(
                  children: [
                    Text(s['icon']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      s['value']!,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      s['label']!,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cardColor = isDark
        ? const Color(0xFF251E4E).withOpacity(0.85)
        : Colors.white;
    final accentColor = isDark
        ? const Color(0xFFC0A6FF)
        : const Color(0xFF7D4B26);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF382F7E) : const Color(0xFFF6DDB7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tappable Avatar with glow
          GestureDetector(
            onTap: () => _showEditProfileBottomSheet(context),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFFC0A6FF), const Color(0xFF7A58D3)]
                          : [const Color(0xFFFDBA74), const Color(0xFFF97316)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark
                      ? const Color(0xFF15112E)
                      : const Color(0xFFFFF7ED),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      _avatarPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/pikachu.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // User Details
          Text(
            _displayName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF3D2F27),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@$_username',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _email,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
          const SizedBox(height: 16),
          // Dynamic Roll No / Branch / Sem details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(
                context,
                isDark,
                icon: Icons.badge_outlined,
                label: 'Roll No',
                val: _rollNo,
              ),
              _buildDetailItem(
                context,
                isDark,
                icon: Icons.school_outlined,
                label: 'Branch',
                val: _branchName,
              ),
              _buildDetailItem(
                context,
                isDark,
                icon: Icons.calendar_today_outlined,
                label: 'Semester',
                val: _isKiitStudent
                    ? _semesterVal.replaceAll('Semester ', 'S')
                    : 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String val,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFFC0A6FF) : theme.colorScheme.primary,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }


}

// Edit Profile Bottom Sheet
class _EditProfileSheet extends StatefulWidget {
  final String currentUsername;
  final String currentDisplayName;
  final String currentAvatarPath;
  final List<Map<String, String>> mascots;
  final Function(String username, String displayName, String avatarPath) onSave;

  const _EditProfileSheet({
    required this.currentUsername,
    required this.currentDisplayName,
    required this.currentAvatarPath,
    required this.mascots,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  late String _avatarPath;

  Timer? _debounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameUnique;
  String _usernameError = '';
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
    _displayNameController.text = widget.currentDisplayName;
    _avatarPath = widget.currentAvatarPath;
    _isUsernameUnique =
        true; // Initial value is unique since it's already theirs
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cleanValue = value.trim();
    if (cleanValue == widget.currentUsername) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameUnique = true;
        _usernameError = '';
      });
      return;
    }

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

  Future<void> _saveChanges() async {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (username.isEmpty || _isUsernameUnique != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No logged in user found');

      // Update in Supabase 2
      await Supabase.instance.client
          .from('user_profiles')
          .update({
            'username': username,
            'display_name': displayName.isEmpty ? null : displayName,
            'avatar_url': _avatarPath,
          })
          .eq('id', user.id);

      widget.onSave(
        username,
        displayName.isEmpty ? 'Focus Fox Student' : displayName,
        _avatarPath,
      );

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: $e',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A3C) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Edit Skulk Profile ⚙️',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Scrolling Mascot List
            Text(
              'SELECT STUDY MASCOT',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.mascots.length,
                itemBuilder: (context, index) {
                  final mascot = widget.mascots[index];
                  final isSelected = _avatarPath == mascot['path'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _avatarPath = mascot['path']!;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: isDark
                            ? const Color(0xFF15112E)
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
            const SizedBox(height: 20),

            // Username input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'USERNAME (REQUIRED & UNIQUE)',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
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
                      fontSize: 10,
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
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                suffixIcon: _isCheckingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
            if (_isCheckingUsername)
              Text(
                'Checking availability...',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (_isUsernameUnique == true &&
                _usernameController.text.trim() != widget.currentUsername)
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

            const SizedBox(height: 16),

            // Display Name input
            Text(
              'DISPLAY NAME (OPTIONAL)',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
              ),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 32),

            // Save Changes button
            ElevatedButton(
              onPressed: (_isUsernameUnique == true && !_isSaving)
                  ? _saveChanges
                  : null,
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save changes',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
