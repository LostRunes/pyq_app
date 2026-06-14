import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/study_together_providers.dart';
import '../widgets/active_lobby_card.dart';
import '../widgets/subject_room_card.dart';
import '../widgets/community_space_tile.dart';

class StudyTogetherScreen extends ConsumerStatefulWidget {
  const StudyTogetherScreen({super.key});

  @override
  ConsumerState<StudyTogetherScreen> createState() =>
      _StudyTogetherScreenState();
}

class _StudyTogetherScreenState extends ConsumerState<StudyTogetherScreen> {
  bool _isSearchingSubjects = false;
  String _subjectSearchQuery = '';
  final TextEditingController _subjectSearchController =
      TextEditingController();

  @override
  void dispose() {
    _subjectSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch categorized room providers
    final lobbiesAsync = ref.watch(activeLobbiesProvider);
    final subjectsAsync = ref.watch(subjectRoomsProvider);
    final communityAsync = ref.watch(communitySpacesProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : const Color.fromARGB(255, 250, 217, 191),
        elevation: 0.5,
        title: Text(
          'Study Together 🎓',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Search feature placeholder for general screen
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isDark
                  ? 'assets/images/skulk_bg_dark2.jpg'
                  : 'assets/images/skulk_bg5.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              isDark
                  ? Colors.black.withOpacity(0.30)
                  : Colors.white.withOpacity(0.45),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studyRoomsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. ACTIVE LOBBIES SECTION (Horizontal Scroll)
              lobbiesAsync.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => const SizedBox.shrink(),
                data: (lobbies) {
                  if (lobbies.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          '🔥 Active Study Lobbies',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.orangeAccent
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: lobbies.length,
                          itemBuilder: (context, index) {
                            return ActiveLobbyCard(lobby: lobbies[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // 2. SUBJECT ROOMS SECTION (Horizontally Scrolling 2-Row Grid with Search)
              subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (subjectRooms) {
                  if (subjectRooms.isEmpty) return const SizedBox.shrink();

                  // Apply search filter in memory
                  var filteredSubjects = subjectRooms;
                  if (_subjectSearchQuery.isNotEmpty) {
                    final query = _subjectSearchQuery.toLowerCase();
                    filteredSubjects = subjectRooms.where((room) {
                      return room.name.toLowerCase().contains(query) ||
                          (room.subjectId?.toLowerCase().contains(query) ??
                              false);
                    }).toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isSearchingSubjects
                              ? Row(
                                  key: const ValueKey('search_active'),
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E1E1E)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.grey[800]!
                                                  : Colors.grey[300]!,
                                            ),
                                          ),
                                          child: TextField(
                                            controller:
                                                _subjectSearchController,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                            ),
                                            autofocus: true,
                                            onChanged: (val) {
                                              setState(() {
                                                _subjectSearchQuery = val;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search subject name or code...',
                                              hintStyle: GoogleFonts.outfit(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isSearchingSubjects = false;
                                          _subjectSearchQuery = '';
                                          _subjectSearchController.clear();
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  key: const ValueKey('search_inactive'),
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        '📘 Subject Rooms',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isSearchingSubjects = true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (filteredSubjects.isEmpty)
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: Text(
                            'No subjects match "$_subjectSearchQuery"',
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 190,
                          child: GridView.builder(
                            scrollDirection: Axis.horizontal,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 90 / 220,
                                ),
                            itemCount: filteredSubjects.length,
                            itemBuilder: (context, index) {
                              return SubjectRoomCard(
                                room: filteredSubjects[index],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // 3. COMMUNITY SPACES SECTION (Compact List)
              communityAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (communitySpaces) {
                  if (communitySpaces.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          '☕ Community Spaces',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: communitySpaces.length,
                        itemBuilder: (context, index) {
                          return CommunitySpaceTile(
                            room: communitySpaces[index],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
