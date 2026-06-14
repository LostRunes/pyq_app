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

  void _showCreateOrJoinDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Personal Room Options',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_box_rounded, color: Colors.blue),
                title: Text('Create Personal Room', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('Start a chat or voice room', style: GoogleFonts.outfit(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateRoomBottomSheet(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.group_add_rounded, color: Colors.green),
                title: Text('Join Room by Code', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('Enter 6-char code shared with you', style: GoogleFonts.outfit(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinRoomDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJoinRoomDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Join Room', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter 6-Character Code',
              hintStyle: GoogleFonts.outfit(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit()),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = controller.text.trim();
                if (code.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room code must be exactly 6 characters')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  final room = await ref.read(roomOperationsProvider).findRoomByCode(code);
                  if (room == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room not found or archived')),
                      );
                    }
                    return;
                  }
                  await ref.read(joinedRoomIdsProvider.notifier).addRoom(room.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully joined room: ${room.name}')),
                    );
                    Navigator.pushNamed(
                      context,
                      '/study-together/chat',
                      arguments: room,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error joining room: $e')),
                    );
                  }
                }
              },
              child: Text('Join', style: GoogleFonts.outfit()),
            ),
          ],
        );
      },
    );
  }

  void _showCreateRoomBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isVoiceEnabled = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Personal Room',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      labelStyle: GoogleFonts.outfit(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: GoogleFonts.outfit(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text('Enable Voice Room', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    subtitle: Text('Users can join both voice and text chat', style: GoogleFonts.outfit(fontSize: 12)),
                    value: isVoiceEnabled,
                    onChanged: (val) {
                      setModalState(() {
                        isVoiceEnabled = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(context);
                      try {
                        final newRoom = await ref.read(roomOperationsProvider).createPersonalRoom(
                          name: name,
                          description: descController.text.trim(),
                          isVoiceEnabled: isVoiceEnabled,
                        );
                        await ref.read(joinedRoomIdsProvider.notifier).addRoom(newRoom.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Room created! Code: ${newRoom.subjectId}'),
                              action: SnackBarAction(
                                label: 'Open',
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/study-together/chat',
                                    arguments: newRoom,
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to create room: $e')),
                          );
                        }
                      }
                    },
                    child: Text('Create', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSubjectRoomDialog(BuildContext context) {
    final allRoomsAsync = ref.read(studyRoomsProvider);
    final joinedNotifier = ref.read(joinedRoomIdsProvider.notifier);
    final joinedIds = ref.read(joinedRoomIdsProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add Subject Rooms', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: allRoomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allRooms) {
                final subjects = allRooms.where((r) => r.type == 'subject').toList();
                return StatefulBuilder(
                  builder: (context, setInnerState) {
                    return ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final room = subjects[index];
                        final isAdded = joinedIds.contains(room.id);
                        return ListTile(
                          title: Text(room.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          subtitle: Text(room.subjectId ?? '', style: GoogleFonts.outfit(fontSize: 12)),
                          trailing: IconButton(
                            icon: Icon(
                              isAdded ? Icons.check_circle : Icons.add_circle_outline_rounded,
                              color: isAdded ? Colors.green : Colors.blue,
                            ),
                            onPressed: () async {
                              if (isAdded) {
                                await joinedNotifier.removeRoom(room.id);
                              } else {
                                await joinedNotifier.addRoom(room.id);
                              }
                              setInnerState(() {});
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
          'Study Together',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Create or Join Room',
            onPressed: () {
              _showCreateOrJoinDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Subject Rooms',
            onPressed: () {
              _showAddSubjectRoomDialog(context);
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                              color: isDark ? Colors.orangeAccent : Colors.orange[800],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active Study Lobbies',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.orangeAccent
                                    : Colors.orange[800],
                              ),
                            ),
                          ],
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
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.library_books_rounded,
                                            size: 18,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Subject Rooms',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.forum_rounded,
                              size: 18,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Community Spaces',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
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
