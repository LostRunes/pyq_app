import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/study_together_providers.dart';
import '../widgets/active_lobby_card.dart';
import '../widgets/subject_room_card.dart';
import '../widgets/community_space_tile.dart';
import '../widgets/personal_room_card.dart';
import 'package:focus_fox/shared/widgets/custom_search_bar.dart';
import 'package:focus_fox/utils/fuzzy_search.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';

class StudyTogetherScreen extends ConsumerStatefulWidget {
  final bool embeddedMode;
  const StudyTogetherScreen({super.key, this.embeddedMode = false});

  @override
  ConsumerState<StudyTogetherScreen> createState() =>
      StudyTogetherScreenState();
}

class StudyTogetherScreenState extends ConsumerState<StudyTogetherScreen> {
  bool _isSearchingSubjects = false;
  String _subjectSearchQuery = '';
  final TextEditingController _subjectSearchController =
      TextEditingController();
  bool _isSubjectRoomsExpanded = true;
  bool _isActiveLobbiesExpanded = true;
  bool _isPersonalRoomsExpanded = true;

  @override
  void dispose() {
    _subjectSearchController.dispose();
    super.dispose();
  }

  void showCreateOrJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Personal Room Options',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_box_rounded, color: Colors.blue),
                title: Text(
                  'Create Personal Room',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Start a chat or voice room',
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showCreateRoomBottomSheet(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.group_add_rounded,
                  color: Colors.green,
                ),
                title: Text(
                  'Join Room by Code',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Enter 6-char code shared with you',
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Join Room',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter 6-Character Code',
              hintStyle: GoogleFonts.outfit(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                    const SnackBar(
                      content: Text('Room code must be exactly 6 characters'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  final room = await ref
                      .read(roomOperationsProvider)
                      .findRoomByCode(code);
                  if (room == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room not found or archived'),
                        ),
                      );
                    }
                    return;
                  }
                  ref.invalidate(studyRoomsProvider);
                  await ref
                      .read(joinedRoomIdsProvider.notifier)
                      .addRoom(room.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully joined room: ${room.name}'),
                      ),
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

  void showCreateRoomBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isVoiceEnabled = false;
    int maxParticipants = 20;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Personal Room',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room Limitations & Closing Policy',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Voice rooms close automatically when empty (0 active participants).\n'
                                  '• Text-only rooms close after 15 minutes of message inactivity.\n'
                                  '• All temporary rooms are permanently deleted 15 minutes after closing.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Room Name',
                        labelStyle: GoogleFonts.outfit(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: GoogleFonts.outfit(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(
                        'Enable Voice Room',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Users can join both voice and text chat',
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                      value: isVoiceEnabled,
                      onChanged: (val) {
                        setModalState(() {
                          isVoiceEnabled = val;
                        });
                      },
                    ),
                    if (isVoiceEnabled) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Max Participants',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          DropdownButton<int>(
                            value: maxParticipants,
                            borderRadius: BorderRadius.circular(12),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  maxParticipants = val;
                                });
                              }
                            },
                            items: [5, 10, 15, 20, 30, 50].map((int val) {
                              return DropdownMenuItem<int>(
                                value: val,
                                child: Text(
                                  '$val Users',
                                  style: GoogleFonts.outfit(fontSize: 14),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(context);
                        try {
                          final newRoom = await ref
                              .read(roomOperationsProvider)
                              .createPersonalRoom(
                                name: name,
                                description: descController.text.trim(),
                                isVoiceEnabled: isVoiceEnabled,
                                maxParticipants: maxParticipants,
                              );
                          ref.invalidate(studyRoomsProvider);
                          await ref
                              .read(joinedRoomIdsProvider.notifier)
                              .addRoom(newRoom.id);
                          if (context.mounted) {
                            Navigator.pushNamed(
                              context,
                              '/study-together/chat',
                              arguments: newRoom,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to create room: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Create',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showAddSubjectRoomDialog(BuildContext context) {
    final allRoomsAsync = ref.read(studyRoomsProvider);
    final joinedNotifier = ref.read(joinedRoomIdsProvider.notifier);
    final joinedIds = ref.read(joinedRoomIdsProvider);
    final branchSubjectsMapAsync = ref.watch(branchSubjectsMapProvider);

    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Add Subject Rooms',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  children: [
                    CustomSearchBar(
                      hintText: 'Search subject, sem, year, branch, code...',
                      margin: const EdgeInsets.only(bottom: 12),
                      onChanged: (val) {
                        setInnerState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    Expanded(
                      child: allRoomsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                        data: (allRooms) {
                          final subjects = allRooms
                              .where((r) => r.type == 'subject')
                              .toList();

                          return branchSubjectsMapAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, _) => Center(
                              child: Text('Error loading subject details'),
                            ),
                            data: (subjectMetaMap) {
                              final filtered = subjects.where((room) {
                                if (FuzzySearch.matches(room.name, searchQuery))
                                  return true;
                                if (room.subjectId != null &&
                                    FuzzySearch.matches(
                                      room.subjectId,
                                      searchQuery,
                                    )) {
                                  return true;
                                }

                                final metaList = subjectMetaMap[room.subjectId];
                                if (metaList != null) {
                                  for (final m in metaList) {
                                    if (FuzzySearch.matches(
                                      m.code,
                                      searchQuery,
                                    ))
                                      return true;
                                    if (FuzzySearch.matches(
                                      m.branchName,
                                      searchQuery,
                                    ))
                                      return true;
                                    if (FuzzySearch.matches(
                                          'semester ${m.semester}',
                                          searchQuery,
                                        ) ||
                                        FuzzySearch.matches(
                                          'sem ${m.semester}',
                                          searchQuery,
                                        ) ||
                                        FuzzySearch.matches(
                                          '${m.semester}',
                                          searchQuery,
                                        )) {
                                      return true;
                                    }
                                    final year = (m.semester + 1) ~/ 2;
                                    if (FuzzySearch.matches(
                                          'year $year',
                                          searchQuery,
                                        ) ||
                                        FuzzySearch.matches(
                                          'yr $year',
                                          searchQuery,
                                        ) ||
                                        FuzzySearch.matches(
                                          '$year year',
                                          searchQuery,
                                        )) {
                                      return true;
                                    }
                                  }
                                }
                                return false;
                              }).toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No matching subject rooms found',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final room = filtered[index];
                                  final isAdded = joinedIds.contains(room.id);

                                  String subInfo = room.subjectId ?? '';
                                  final metaList =
                                      subjectMetaMap[room.subjectId];
                                  if (metaList != null && metaList.isNotEmpty) {
                                    final first = metaList.first;
                                    final year = (first.semester + 1) ~/ 2;
                                    subInfo =
                                        '${first.code} • Sem ${first.semester} • Yr $year';
                                  }

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    title: Text(
                                      room.name,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      subInfo,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        isAdded
                                            ? Icons.check_circle
                                            : Icons.add_circle_outline_rounded,
                                        color: isAdded
                                            ? Colors.green
                                            : Colors.blue,
                                        size: 22,
                                      ),
                                      onPressed: () async {
                                        if (isAdded) {
                                          await joinedNotifier.removeRoom(
                                            room.id,
                                          );
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
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
    final personalAsync = ref.watch(personalRoomsProvider);

    return Scaffold(
      backgroundColor: widget.embeddedMode
          ? Colors.transparent
          : (isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9)),
      appBar: widget.embeddedMode
          ? null
          : AppBar(
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
              iconTheme: IconThemeData(
                color: isDark ? Colors.white : Colors.black87,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: 'Create or Join Room',
                  onPressed: () {
                    showCreateOrJoinDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.library_add_rounded),
                  tooltip: 'Add Subject Rooms',
                  onPressed: () {
                    showAddSubjectRoomDialog(context);
                  },
                ),
              ],
            ),
      body: Stack(
        children: [
          // Cozy panda reading scenario (stuck to bottom in the background)
          Positioned(
            bottom: -53,
            left: 0,
            right: 0,
            child: Image.asset(
              isDark
                  ? 'assets/images/panda_reading_scenario_dark.png'
                  : 'assets/images/panda_reading_scenario.png',
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studyRoomsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                FadeInSlide(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 20,
                      left: 4,
                      right: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chat Rooms',
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Join lobbies, community spaces, or create your own room',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          tooltip: 'Create or Join Room',
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            showCreateOrJoinDialog(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.library_add_rounded),
                          tooltip: 'Add Subject Rooms',
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            showAddSubjectRoomDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 1. COMMUNITY SPACES SECTION (Top, always visible, non-collapsible)
                communityAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (communitySpaces) {
                    if (communitySpaces.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.forum_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Community Spaces',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFF818CF8)
                                      : const Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 154,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              scrollDirection: Axis.horizontal,
                              itemCount: communitySpaces.length,
                              itemBuilder: (context, index) {
                                final room = communitySpaces[index];
                                final nameLower = room.name.toLowerCase();
                                String assetName = 'assets/images/coffee.png';
                                Color bgCircle = isDark
                                    ? const Color(0xFF2D2419)
                                    : const Color(0xFFFFF2E2);
                                Color badgeColor = const Color(0xFFFFA000);

                                if (nameLower.contains('placement')) {
                                  assetName = 'assets/images/plant.png';
                                  bgCircle = isDark
                                      ? const Color(0xFF1B2E1E)
                                      : const Color(0xFFE8F5E9);
                                  badgeColor = const Color(0xFF4CAF50);
                                } else if (nameLower.contains('voice') ||
                                    nameLower.contains('lounge')) {
                                  assetName = 'assets/images/headphones.png';
                                  bgCircle = isDark
                                      ? const Color(0xFF281E3D)
                                      : const Color(0xFFF3E5F5);
                                  badgeColor = const Color(0xFF9C27B0);
                                }

                                return Consumer(
                                  builder: (context, ref, child) {
                                    final onlineCount = ref.watch(
                                      roomPresenceProvider(room.id),
                                    );

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/study-together/chat',
                                          arguments: room,
                                        );
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Column(
                                          children: [
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    color: bgCircle,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Image.asset(
                                                    assetName,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: -2,
                                                  right: -2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: badgeColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 18,
                                                          minHeight: 18,
                                                        ),
                                                    child: Center(
                                                      child: Text(
                                                        '$onlineCount',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              room.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              room.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color:
                                                            Colors.greenAccent,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$onlineCount online',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 1.5 PERSONAL ROOMS SECTION (Collapsible with +/- toggle)
                personalAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (personalRooms) {
                    if (personalRooms.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFFC084FC)
                                        : const Color(0xFF7E22CE),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Personal Rooms',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFFC084FC)
                                          : const Color(0xFF7E22CE),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  _isPersonalRoomsExpanded
                                      ? Icons.remove_circle_outline_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPersonalRoomsExpanded =
                                        !_isPersonalRoomsExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: personalRooms.length,
                                  itemBuilder: (context, index) {
                                    return PersonalRoomCard(
                                      room: personalRooms[index],
                                    );
                                  },
                                ),
                              ],
                            ),
                            crossFadeState: _isPersonalRoomsExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 2. SUBJECT ROOMS SECTION (Middle, collapsible with +/- toggle)
                subjectsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (subjectRooms) {
                    if (subjectRooms.isEmpty) return const SizedBox.shrink();

                    // Apply search filter in memory
                    var filteredSubjects = subjectRooms;
                    if (_subjectSearchQuery.isNotEmpty) {
                      filteredSubjects = subjectRooms.where((room) {
                        return FuzzySearch.matches(
                              room.name,
                              _subjectSearchQuery,
                            ) ||
                            FuzzySearch.matches(
                              room.subjectId,
                              _subjectSearchQuery,
                            );
                      }).toList();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.library_books_rounded,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFF2DD4BF)
                                        : const Color(0xFF0F766E),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Subject Rooms',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFF2DD4BF)
                                          : const Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      _isSearchingSubjects
                                          ? Icons.close_rounded
                                          : Icons.search_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSearchingSubjects =
                                            !_isSearchingSubjects;
                                        if (!_isSearchingSubjects) {
                                          _subjectSearchQuery = '';
                                          _subjectSearchController.clear();
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      _isSubjectRoomsExpanded
                                          ? Icons.remove_circle_outline_rounded
                                          : Icons.add_circle_outline_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isSubjectRoomsExpanded =
                                            !_isSubjectRoomsExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isSearchingSubjects) ...[
                                  const SizedBox(height: 12),
                                  CustomSearchBar(
                                    controller: _subjectSearchController,
                                    hintText: 'Search subject name or code...',
                                    height: 40,
                                    autofocus: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _subjectSearchQuery = val;
                                      });
                                    },
                                  ),
                                ],
                                const SizedBox(height: 16),
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
                              ],
                            ),
                            crossFadeState: _isSubjectRoomsExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 3. ACTIVE LOBBIES SECTION (Bottom, collapsible with +/- toggle)
                lobbiesAsync.when(
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (lobbies) {
                    if (lobbies.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active Study Lobbies',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  _isActiveLobbiesExpanded
                                      ? Icons.remove_circle_outline_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isActiveLobbiesExpanded =
                                        !_isActiveLobbiesExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 210,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: lobbies.length,
                                    itemBuilder: (context, index) {
                                      return ActiveLobbyCard(
                                        lobby: lobbies[index],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            crossFadeState: _isActiveLobbiesExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 190),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
