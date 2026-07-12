import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:focus_fox/app/app.dart';
import 'package:focus_fox/services/push_notification_service.dart';
import 'package:focus_fox/core/providers.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/core/providers/user_profile_provider.dart';
import 'package:focus_fox/core/providers/theme_provider.dart';
import 'package:focus_fox/core/providers/bee_provider.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';
import 'package:focus_fox/features/prep_zone/presentation/providers/prep_zone_providers.dart';
import 'package:focus_fox/features/utilities/presentation/providers/utilities_providers.dart';
import 'package:focus_fox/features/skulk/presentation/screens/skulk_feed_screen.dart';
import 'package:focus_fox/features/skulk/presentation/providers/skulk_providers.dart';
import 'package:focus_fox/features/skulk/study_together/presentation/screens/study_together_screen.dart';
import 'package:focus_fox/features/subjects/presentation/screens/subjects_page.dart';
import 'package:focus_fox/features/prep_zone/presentation/screens/prep_zone_page.dart';
import 'package:focus_fox/features/utilities/presentation/screens/utilities_page.dart';
import 'package:focus_fox/services/analytics_service.dart';
import 'package:focus_fox/shared/widgets/theme_toggle_button.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import 'package:focus_fox/features/auth/presentation/widgets/bee_leaderboard_sheet.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final String branchId;
  final int semester;
  static final GlobalKey profileIconKey = GlobalKey();
  const MainNavigationScreen({
    super.key,
    required this.branchId,
    required this.semester,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  // Removed _currentSemester / _currentBranchId local fields:
  // providers are now the single source of truth.
  int _currentIndex =
      0; // 0: Subjects, 1: Prep Zone, 2: Utilities, 3: Study Rooms, 4: Skulk

  // Guard flag: suppresses onPageChanged during programmatic animateToPage()
  // so the blob doesn't flicker through intermediate positions.
  bool _isAnimatingPage = false;

  // Track back button presses
  DateTime? _lastBackPressTime;
  bool _dialogShowing = false;

  // Skulk Feed Header Search State
  bool _isSearching = false;
  final TextEditingController _skulkSearchController = TextEditingController();

  // Animation controller for fluid water wobble
  late AnimationController _wobbleController;
  late PageController _pageController;

  // GlobalKey to access StudyTogetherScreenState so we can trigger its dialogs
  // from the main AppBar action buttons when the Rooms tab is active.
  final GlobalKey<StudyTogetherScreenState> _studyRoomsKey =
      GlobalKey<StudyTogetherScreenState>();

  @override
  void initState() {
    super.initState();

    // Write providers synchronously — no microtask, so the first build
    // already has the correct branch/semester and only one fetch is made.
    ref.read(selectedSemesterProvider.notifier).setSemester(widget.semester);
    ref.read(selectedBranchIdProvider.notifier).setBranchId(widget.branchId);

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    final initialIdx = ref.read(mainNavigationIndexProvider);
    _pageController = PageController(initialPage: initialIdx);

    // Subjects tab is active on startup — open the fade animation window
    if (initialIdx == 0) {
      SubjectCardFade.onPageActivated();
    }

    // Register FCM device token for push notifications
    unawaited(PushNotificationService.registerDeviceToken());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the global route observer so we can pause/resume the
    // wobble animation when a child route is pushed on top of this screen.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  /// Called when a new route is pushed on top of this one.
  /// Pause the wobble so it doesn't burn CPU while the nav bar is hidden.
  @override
  void didPushNext() => _wobbleController.stop();

  /// Called when the route on top is popped and this screen is visible again.
  @override
  void didPopNext() => _wobbleController.repeat(reverse: true);

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _wobbleController.dispose();
    _pageController.dispose();
    _skulkSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _currentIndex = ref.watch(mainNavigationIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If search is active, close the search first
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _skulkSearchController.clear();
            ref.read(subjectsSearchProvider.notifier).updateSearch('');
            ref.read(prepZoneSearchProvider.notifier).updateSearch('');
            ref.read(utilitiesSearchProvider.notifier).updateSearch('');
            ref.read(skulkFeedSearchProvider.notifier).updateSearch('');
          });
          return;
        }

        // If not on the first tab, go to the first tab
        if (_currentIndex != 0) {
          ref.read(mainNavigationIndexProvider.notifier).setIndex(0);
          _isAnimatingPage = true;
          _pageController
              .animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              )
              .then((_) {
                if (mounted) setState(() => _isAnimatingPage = false);
              });
          return;
        }

        // We are on index 0. Handle double back press / dialog exit.
        final now = DateTime.now();
        final backButtonHasNotBeenPressedRecently = _lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedRecently) {
          _lastBackPressTime = now;
          
          if (!_dialogShowing) {
            _dialogShowing = true;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                title: Text(
                  'Exit App?',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                ),
                content: Text(
                  'Do you want to exit the app?',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _dialogShowing = false;
                      Navigator.pop(context);
                    },
                    child: Text(
                      'No',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
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
                    onPressed: () {
                      _dialogShowing = false;
                      SystemNavigator.pop();
                    },
                    child: Text(
                      'Exit',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ).then((_) {
              _dialogShowing = false;
            });
          }
        } else {
          // Second tap within 2 seconds
          if (_dialogShowing) {
            Navigator.pop(context); // Close dialog if open
            _dialogShowing = false;
          }
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: _isSearching ? 56 : 110,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _skulkSearchController.clear();
                    ref.read(subjectsSearchProvider.notifier).updateSearch('');
                    ref.read(prepZoneSearchProvider.notifier).updateSearch('');
                    ref.read(utilitiesSearchProvider.notifier).updateSearch('');
                    ref.read(skulkFeedSearchProvider.notifier).updateSearch('');
                  });
                },
              )
            : Row(
                children: [
                  const SizedBox(width: 8),
                  const NotificationBell(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                ],
              ),
        title: _isSearching
            ? Container(
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1B4B).withOpacity(0.4)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    width: 1.0,
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
                          : _currentIndex == 4
                          ? 'Search doubts, titles or tags...'
                          : 'Search...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      icon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    onChanged: (val) {
                      if (_currentIndex == 0) {
                        ref
                            .read(subjectsSearchProvider.notifier)
                            .updateSearch(val);
                      } else if (_currentIndex == 1) {
                        ref
                            .read(prepZoneSearchProvider.notifier)
                            .updateSearch(val);
                      } else if (_currentIndex == 2) {
                        ref
                            .read(utilitiesSearchProvider.notifier)
                            .updateSearch(val);
                      } else if (_currentIndex == 4) {
                        ref
                            .read(skulkFeedSearchProvider.notifier)
                            .updateSearch(val);
                      }
                    },
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        AnalyticsService.logSearchPerformed(val.trim());
                      }
                    },
                  ),
                ),
              )
            : null,
        centerTitle: false,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _skulkSearchController.clear();
                  if (_currentIndex == 0) {
                    ref.read(subjectsSearchProvider.notifier).updateSearch('');
                  } else if (_currentIndex == 1) {
                    ref.read(prepZoneSearchProvider.notifier).updateSearch('');
                  } else if (_currentIndex == 2) {
                    ref.read(utilitiesSearchProvider.notifier).updateSearch('');
                  } else if (_currentIndex == 4) {
                    ref.read(skulkFeedSearchProvider.notifier).updateSearch('');
                  }
                });
              },
            ),

          if (!_isSearching) ...[
            const ThemeToggleButton(),
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              icon: Container(
                key: MainNavigationScreen.profileIconKey,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.4),
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
                        // Use NetworkImage for remote URLs (e.g. Google OAuth avatar),
                        // AssetImage for bundled assets.
                        final ImageProvider imageProvider =
                            avatarUrl.startsWith('http')
                            ? NetworkImage(avatarUrl)
                            : AssetImage(avatarUrl) as ImageProvider;
                        return CircleAvatar(
                          radius: 16,
                          backgroundImage: imageProvider,
                          backgroundColor: Colors.transparent,
                        );
                      },
                      loading: () => const CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage(
                          'assets/images/pikachu.png',
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      error: (_, __) => const CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage(
                          'assets/images/pikachu.png',
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
              ),
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.pushNamed(context, '/profile');
                } else if (value == 'settings') {
                  Navigator.pushNamed(context, '/settings');
                } else if (value == 'about') {
                  Navigator.pushNamed(context, '/about');
                } else if (value == 'theme_toggle') {
                  ref.read(themeModeProvider.notifier).toggle();
                } else if (value == 'instagram') {
                  final Uri url = Uri.parse('https://www.instagram.com/focusfox.exe?igsh=NDBlcXhsb2R0czlo');
                  unawaited(launchUrl(url, mode: LaunchMode.externalApplication));
                } else if (value == 'logout') {
                  _showLogoutDialog(context);
                } else if (value == 'bee_leaderboard') {
                  Navigator.pushNamed(context, '/bee_dashboard');
                }
              },
              itemBuilder: (BuildContext context) {
                return [
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
                  PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'bee_leaderboard',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFFF9F0A),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Bee Leaderboard',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Quest Item (bee counter + toggle) — stays open on tap ──
                  PopupMenuItem<String>(
                    // No value — prevents PopupMenuItem from popping the menu
                    padding: EdgeInsets.zero,
                    child: Consumer(
                      builder: (context, watchRef, _) {
                        // Live watch inside the popup — rebuilds on every toggle
                        final liveBeeEnabled = watchRef.watch(
                          beeEnabledProvider,
                        );
                        final liveBeeCount = watchRef.watch(
                          beeTapCountProvider,
                        );
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            watchRef.read(beeEnabledProvider.notifier).toggle();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                // Bee emoji + golden count badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Text(
                                      '🐝',
                                      style: GoogleFonts.outfit(fontSize: 18),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF9F0A),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '$liveBeeCount',
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Quest',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        liveBeeEnabled
                                            ? 'Bee is active'
                                            : 'Bee is off',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: liveBeeEnabled
                                              ? const Color(0xFFFF9F0A)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Animated pill — driven by live state, always animates
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  width: 40,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: liveBeeEnabled
                                        ? const Color(0xFFFF9F0A)
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: AnimatedAlign(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    alignment: liveBeeEnabled
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  PopupMenuItem(
                    value: 'instagram',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFFE1306C),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Instagram',
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
                ];
              },
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: isDark
              ? DecorationImage(
                  image: const AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF171330).withOpacity(0.55),
                    BlendMode.srcOver,
                  ),
                )
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: 76 + MediaQuery.of(context).padding.bottom,
            ),
            child: PageView(
              key: const PageStorageKey('main_navigation_page_view'),
              controller: _pageController,
              onPageChanged: (index) {
                // Skip intermediate callbacks fired during a programmatic
                // animateToPage() call — this is what caused the blob to flicker.
                if (_isAnimatingPage) return;
                // All 5 nav indices map 1:1 to PageView pages now.
                ref.read(mainNavigationIndexProvider.notifier).setIndex(index);
                setState(() {
                  // Do NOT reset _isSearching here — that would dismiss the
                  // keyboard unexpectedly when the user swipes between tabs.
                  _skulkSearchController.clear();
                  ref.read(subjectsSearchProvider.notifier).updateSearch('');
                  ref.read(prepZoneSearchProvider.notifier).updateSearch('');
                  ref.read(utilitiesSearchProvider.notifier).updateSearch('');
                  ref.read(skulkFeedSearchProvider.notifier).updateSearch('');
                });
                // When swiping to subjects tab, open the fade animation window
                if (index == 0) SubjectCardFade.onPageActivated();
              },
              children: [
                const SubjectsPage(),
                const PrepZonePage(),
                const UtilitiesPage(),
                StudyTogetherScreen(key: _studyRoomsKey, embeddedMode: true),
                _buildSkulkPage(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCuteBottomNavBar(context),
      ),
    );
  }

  Widget _buildCuteBottomNavBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 5 tabs — slightly narrower slots
    final tabWidth = size.width / 5;
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
    // Study Rooms gets a distinct teal accent
    final Color studyRoomsActive = isDark
        ? const Color(0xFF4DD9E0)
        : const Color(0xFF0083B0);
    final Color orangeActiveBg = isDark
        ? const Color(0x2BC0A6FF)
        : const Color(0x1AD37D3E);
    final Color studyRoomsActiveBg = isDark
        ? const Color(0x2B4DD9E0)
        : const Color(0x1A0083B0);
    final Color orangeInactive = isDark
        ? const Color(0xFF8A7CB5)
        : const Color(0x997A6456);
    final Color shadowColor = isDark
        ? Colors.black38
        : Colors.black.withOpacity(0.06);

    // Pick the correct blob color based on current index
    final blobBg = _currentIndex == 3 ? studyRoomsActiveBg : orangeActiveBg;
    final blobBorder = _currentIndex == 3 ? studyRoomsActive : orangeActive;

    // Blob is 68px wide for 5 tabs so it fits without overlap
    const double blobW = 68;

    return Container(
      height: 76 + bottomPadding,
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
            left: (_currentIndex * tabWidth) + (tabWidth - blobW) / 2,
            top: 10,
            child: AnimatedBuilder(
              animation: _wobbleController,
              builder: (context, child) {
                final val = _wobbleController.value;
                // Undulating organic border radius simulating a liquid water droplet
                return Container(
                  width: blobW,
                  height: 50,
                  decoration: BoxDecoration(
                    color: blobBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26 + 12 * val),
                      topRight: Radius.circular(34 - 12 * val),
                      bottomLeft: Radius.circular(30 - 10 * val),
                      bottomRight: Radius.circular(28 + 10 * val),
                    ),
                    border: Border.all(
                      color: blobBorder.withOpacity(0.25 * val),
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
                // Study Rooms — embedded as a real PageView page
                _buildNavBarItem(
                  3,
                  Icons.groups_rounded,
                  'Lobbies',
                  studyRoomsActive,
                  orangeInactive,
                ),
                _buildNavBarItem(
                  4,
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
        // When tapping subjects tab, open the fade animation window
        if (index == 0) SubjectCardFade.onPageActivated();
        ref.read(mainNavigationIndexProvider.notifier).setIndex(index);
        setState(() {
          _isSearching = false;
          _skulkSearchController.clear();
          ref.read(skulkFeedSearchProvider.notifier).updateSearch('');
        });
        // Animate the PageView — all 5 nav indices map 1:1 to PageView pages.
        _isAnimatingPage = true;
        _pageController
            .animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
            .then((_) {
              if (mounted) setState(() => _isAnimatingPage = false);
            });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkulkPage(BuildContext context) {
    // Watch directly from providers — reactive state updates.
    final branchId = ref.watch(selectedBranchIdProvider);
    final semester = ref.watch(selectedSemesterProvider);
    return SkulkFeedScreen(branchId: branchId, semester: semester);
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
                // Capture navigator BEFORE await - context is not safe across async gaps
                final navigator = Navigator.of(context);
                await signOutCompletely(ref: ref);
                // Navigate first so the snackbar appears on the login screen's messenger
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
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
