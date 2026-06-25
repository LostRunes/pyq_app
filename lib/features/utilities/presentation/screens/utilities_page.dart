import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/features/utilities/presentation/providers/utilities_providers.dart';
import 'package:focus_fox/utils/fuzzy_search.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';
import 'package:focus_fox/features/pyqs/presentation/providers/pyq_providers.dart';
import 'package:focus_fox/features/profile/presentation/widgets/heatmap_widget.dart';
import 'package:focus_fox/features/utilities/presentation/providers/activity_providers.dart';

class UtilitiesPage extends ConsumerWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(utilitiesSearchProvider);
    final isDark = theme.brightness == Brightness.dark;

    final utils = [
      {
        'title': 'GPA Calculator',
        'desc': 'Track grades & semester GPA',
        'icon': Icons.calculate_rounded,
        'route': '/gpa_calculator',
        'color': const Color(0xFF10B981), // Emerald
      },
      {
        'title': 'Upload Notes',
        'desc': 'Share study notes & materials',
        'icon': Icons.cloud_upload_rounded,
        'route': '/upload_notes',
        'color': const Color(0xFF6366F1), // Indigo
      },
      {
        'title': 'Syllabus',
        'desc': 'Explore subjects & credits',
        'icon': Icons.collections_bookmark_rounded,
        'route': '/syllabus',
        'color': const Color(0xFFF59E0B), // Amber
      },
      {
        'title': 'Focus Timer',
        'desc': 'Set a timer to stay focused',
        'icon': Icons.timer_rounded,
        'route': '/focus_timer',
        'color': const Color(0xFFEC4899), // Pink
      },
    ];

    final filteredUtils = utils.where((util) {
      return FuzzySearch.matches(util['title'] as String?, searchQuery) ||
          FuzzySearch.matches(util['desc'] as String?, searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utilities',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Access essential tools & plan your day',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Heatmap Tracker at the top
          const StudyActivityHeatmap(),
          const SizedBox(height: 24),
          // Interactive To-Do Dashboard
          const ToDoDashboard(),
          const SizedBox(height: 24),
          Text(
            'Core Features',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          filteredUtils.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Text(
                    'No matching utilities found 🔍',
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredUtils.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, index) {
                    final util = filteredUtils[index];
                    final Color utilColor = util['color'] as Color;
                    return InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, util['route'] as String);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1B4B).withOpacity(0.2) : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? utilColor.withOpacity(0.15) : utilColor.withOpacity(0.1),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: utilColor.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: utilColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                util['icon'] as IconData,
                                color: utilColor,
                                size: 22,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  util['title'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  util['desc'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class ToDoDashboard extends ConsumerStatefulWidget {
  const ToDoDashboard({super.key});

  @override
  ConsumerState<ToDoDashboard> createState() => _ToDoDashboardState();
}

class _ToDoDashboardState extends ConsumerState<ToDoDashboard> {
  String _selectedType = 'Custom'; // 'Custom', 'Subject', 'Algo'
  final _customTaskController = TextEditingController();
  
  String? _selectedSubjectId;
  String? _selectedTopicId;
  String? _selectedAlgoTopic;

  final List<String> _algoTopics = [
    'Array',
    'Searching',
    'Recursion',
    'String',
    'Stack',
    'Queue',
    'Linked List',
    'Tree',
    'Graph',
  ];

  @override
  void dispose() {
    _customTaskController.dispose();
    super.dispose();
  }

  void _addTask() {
    String title = '';
    if (_selectedType == 'Custom') {
      title = _customTaskController.text.trim();
    } else if (_selectedType == 'Subject') {
      if (_selectedSubjectId == null || _selectedTopicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both subject and topic')),
        );
        return;
      }
      final subjects = ref.read(allSubjectsProvider).value ?? [];
      final topics = ref.read(topicsProvider(_selectedSubjectId!)).value ?? [];
      final sub = subjects.firstWhere((s) => s.id == _selectedSubjectId);
      final top = topics.firstWhere((t) => t.id == _selectedTopicId);
      title = '${sub.name} → ${top.name}';
    } else if (_selectedType == 'Algo') {
      if (_selectedAlgoTopic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an Algo & Code topic')),
        );
        return;
      }
      title = 'Algo & Code → $_selectedAlgoTopic';
    }

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
      );
      return;
    }

    ref.read(toDoListProvider.notifier).addTask(title, _selectedType);
    _customTaskController.clear();
    setState(() {
      _selectedTopicId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todoList = ref.watch(toDoListProvider);

    final cardBgColor = isDark
        ? const Color(0xFF1A1A2E).withOpacity(0.9)
        : Colors.white;

    final borderThemeColor = isDark
        ? const Color(0xFF6366F1).withOpacity(0.15)
        : Colors.indigo.withOpacity(0.1);

    // Subject/topic dropdown logic
    final subjects = ref.watch(allSubjectsProvider).value ?? [];
    final topics = _selectedSubjectId != null
        ? ref.watch(topicsProvider(_selectedSubjectId!)).value ?? []
        : [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderThemeColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF6366F1), size: 24),
              const SizedBox(width: 8),
              Text(
                'To Do Dashboard',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Type selector Row
          Row(
            children: ['Custom', 'Subject', 'Algo'].map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(
                      type == 'Algo' ? 'Algo & Code' : type == 'Subject' ? 'Subject Topic' : 'Custom Task',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black87),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.08),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedType = type;
                        });
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Conditional inputs based on type
          if (_selectedType == 'Custom')
            TextField(
              controller: _customTaskController,
              decoration: InputDecoration(
                hintText: 'Enter custom task...',
                hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderThemeColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
            )
          else if (_selectedType == 'Subject')
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  hint: Text('Select Subject', style: GoogleFonts.outfit(fontSize: 12)),
                  dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  items: subjects.map((sub) {
                    return DropdownMenuItem<String>(
                      value: sub.id,
                      child: Text(sub.name, style: GoogleFonts.outfit(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSubjectId = val;
                      _selectedTopicId = null;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                if (_selectedSubjectId != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedTopicId,
                    hint: Text('Select Topic', style: GoogleFonts.outfit(fontSize: 12)),
                    dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    items: topics.map((top) {
                      return DropdownMenuItem<String>(
                        value: top.id,
                        child: Text(top.name, style: GoogleFonts.outfit(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTopicId = val;
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ]
              ],
            )
          else if (_selectedType == 'Algo')
            DropdownButtonFormField<String>(
              value: _selectedAlgoTopic,
              hint: Text('Select Algo & Code Topic', style: GoogleFonts.outfit(fontSize: 12)),
              dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              items: _algoTopics.map((topic) {
                return DropdownMenuItem<String>(
                  value: topic,
                  child: Text(topic, style: GoogleFonts.outfit(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedAlgoTopic = val;
                });
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addTask,
            icon: const Icon(Icons.add, size: 16),
            label: Text('Add to Dashboard', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (todoList.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: Colors.white10),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                final task = todoList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        activeColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          ref.read(toDoListProvider.notifier).toggleTask(task.id);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.type == 'Algo'
                                    ? const Color(0xFF8B5CF6).withOpacity(0.15)
                                    : task.type == 'Subject'
                                        ? const Color(0xFF10B981).withOpacity(0.15)
                                        : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.type == 'Algo'
                                    ? 'Algo & Code'
                                    : task.type == 'Subject'
                                        ? 'Subject Topic'
                                        : 'Custom',
                                style: GoogleFonts.outfit(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: task.type == 'Algo'
                                      ? const Color(0xFFC0A6FF)
                                      : task.type == 'Subject'
                                          ? const Color(0xFF10B981)
                                          : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(toDoListProvider.notifier).removeTask(task.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
