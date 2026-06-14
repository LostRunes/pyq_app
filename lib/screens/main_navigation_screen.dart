import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../features/skulk/presentation/screens/skulk_feed_screen.dart';
import '../features/skulk/presentation/providers/skulk_providers.dart';
import 'subjects_page.dart';
import 'prep_zone_page.dart';
import 'utilities_page.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final String branchId;
  final int semester;
  const MainNavigationScreen({
    super.key,
    required this.branchId,
    required this.semester,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late int _currentSemester;
  late String _currentBranchId;
  int _currentIndex = 0; // 0: Subjects, 1: Syllabus, 2: Dashboard, 3: Skulk

  // Skulk Feed Header Search State
  bool _isSearching = false;
  final TextEditingController _skulkSearchController = TextEditingController();

  // Animation controller for fluid water wobble
  late AnimationController _wobbleController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentSemester = widget.semester;
    _currentBranchId = widget.branchId;

    Future.microtask(() {
      ref.read(selectedSemesterProvider.notifier).setSemester(widget.semester);
      ref.read(selectedBranchIdProvider.notifier).setBranchId(widget.branchId);
    });

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _pageController.dispose();
    _skulkSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSemester = ref.watch(selectedSemesterProvider);
    final activeBranchId = ref.watch(selectedBranchIdProvider);

    if (_currentSemester != activeSemester) {
      _currentSemester = activeSemester;
    }
    _currentBranchId = activeBranchId;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: _isSearching ? 56 : (_currentIndex == 3 ? 56 : 110),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _skulkSearchController.clear();
                    ref.read(subjectsSearchProvider.notifier).state = '';
                    ref.read(prepZoneSearchProvider.notifier).state = '';
                    ref.read(utilitiesSearchProvider.notifier).state = '';
                    ref.read(skulkFeedSearchProvider.notifier).state = '';
                  });
                },
              )
            : (_currentIndex == 3
                ? const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: NotificationBell(),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new notifications. 🔔'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                    ],
                  )),
        title: _isSearching
            ? Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1E1B4B).withOpacity(0.4) 
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.12) 
                        : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: TextField(
                    controller: _skulkSearchController,
                    autofocus: true,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: _currentIndex == 0
                          ? 'Search subjects or codes...'
                          : _currentIndex == 1
                              ? 'Search preparation tools...'
                              : _currentIndex == 2
                                  ? 'Search utilities...'
                                  : 'Search doubts, titles or tags...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      icon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    onChanged: (val) {
                      if (_currentIndex == 0) {
                        ref.read(subjectsSearchProvider.notifier).state = val;
                      } else if (_currentIndex == 1) {
                        ref.read(prepZoneSearchProvider.notifier).state = val;
                      } else if (_currentIndex == 2) {
                        ref.read(utilitiesSearchProvider.notifier).state = val;
                      } else if (_currentIndex == 3) {
                        ref.read(skulkFeedSearchProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
              )
            : (_currentIndex == 3
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skulk',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Image.asset(
                        'assets/images/lil_fox.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ],
                  )
                : null),
        centerTitle: _currentIndex == 3,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _skulkSearchController.clear();
                  if (_currentIndex == 0) {
                    ref.read(subjectsSearchProvider.notifier).state = '';
                  } else if (_currentIndex == 1) {
                    ref.read(prepZoneSearchProvider.notifier).state = '';
                  } else if (_currentIndex == 2) {
                    ref.read(utilitiesSearchProvider.notifier).state = '';
                  } else if (_currentIndex == 3) {
                    ref.read(skulkFeedSearchProvider.notifier).state = '';
                  }
                });
              },
            )
          else if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),

          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: ref
                  .watch(userProfileProvider)
                  .when(
                    data: (profile) {
                      final avatarUrl =
                          profile?['avatar_url']?.toString() ??
                          'assets/images/pikachu.png';
                      return CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage(avatarUrl),
                        backgroundColor: Colors.transparent,
                      );
                    },
                    loading: () => const CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage('assets/images/pikachu.png'),
                      backgroundColor: Colors.transparent,
                    ),
                    error: (_, __) => const CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage('assets/images/pikachu.png'),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              } else if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
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
            : null,
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isSearching = false;
                _skulkSearchController.clear();
                ref.read(subjectsSearchProvider.notifier).state = '';
                ref.read(prepZoneSearchProvider.notifier).state = '';
                ref.read(utilitiesSearchProvider.notifier).state = '';
                ref.read(skulkFeedSearchProvider.notifier).state = '';
              });
            },
            children: [
              const SubjectsPage(),
              const PrepZonePage(),
              const UtilitiesPage(),
              _buildSkulkPage(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCuteBottomNavBar(context),
    );
  }

  Widget _buildCuteBottomNavBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tabWidth = size.width / 4;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Violet starry night palette in dark mode, light theme cream-orange palette in light mode
    final Color orangeBgStart = isDark
        ? const Color(0xFF251E4E)
        : const Color.fromARGB(255, 251, 203, 158);
    final Color orangeBgEnd = isDark
        ? const Color(0xFF15112E)
        : const Color.fromARGB(255, 238, 206, 154);
    final Color orangeActive = isDark
        ? const Color(0xFFC0A6FF)
        : const Color.fromARGB(255, 90, 41, 0);
    final Color orangeActiveBg = isDark
        ? const Color(0x2BC0A6FF)
        : const Color(0x1AD37D3E);
    final Color orangeInactive = isDark
        ? const Color(0xFF8A7CB5)
        : const Color(0x997A6456);
    final Color shadowColor = isDark
        ? Colors.black38
        : Colors.black.withOpacity(0.06);

    return Container(
      height: 80 + bottomPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [orangeBgStart, orangeBgEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated Fluid Water Drop behind the active tab
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            left: (_currentIndex * tabWidth) + (tabWidth - 84) / 2,
            top: 13,
            child: AnimatedBuilder(
              animation: _wobbleController,
              builder: (context, child) {
                final val = _wobbleController.value;
                // Undulating organic border radius simulating a liquid water droplet
                return Container(
                  width: 84,
                  height: 52,
                  decoration: BoxDecoration(
                    color: orangeActiveBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26 + 12 * val),
                      topRight: Radius.circular(34 - 12 * val),
                      bottomLeft: Radius.circular(30 - 10 * val),
                      bottomRight: Radius.circular(28 + 10 * val),
                    ),
                    border: Border.all(
                      color: orangeActive.withOpacity(0.25 * val),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
          // Nav Bar Items
          Positioned.fill(
            bottom: bottomPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavBarItem(
                  0,
                  Icons.book_rounded,
                  'Subjects',
                  orangeActive,
                  orangeInactive,
                ),
                _buildNavBarItem(
                  1,
                  Icons.school_rounded,
                  'Prep Zone',
                  orangeActive,
                  orangeInactive,
                ),
                _buildNavBarItem(
                  2,
                  Icons.widgets_rounded,
                  'Utilities',
                  orangeActive,
                  orangeInactive,
                ),
                _buildNavBarItem(
                  3,
                  Icons.diversity_3_rounded,
                  'Skulk',
                  orangeActive,
                  orangeInactive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          if (index != 3) {
            _isSearching = false;
            _skulkSearchController.clear();
            ref.read(skulkFeedSearchProvider.notifier).state = '';
          }
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkulkPage(BuildContext context) {
    return SkulkFeedScreen(
      branchId: _currentBranchId,
      semester: _currentSemester,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Confirm Logout 😢',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to log out completely?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              if (mounted) {
                // Capture navigator and messenger BEFORE await - context is not safe across async gaps
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await signOutCompletely();
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged out successfully! See you soon. 👋',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

}
