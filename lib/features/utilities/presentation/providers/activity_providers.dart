import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';

class ToDoTask {
  final String id;
  final String title;
  final String type; // 'subject', 'algo', 'custom'
  final bool isCompleted;
  final String? completedDate; // yyyy-MM-dd

  ToDoTask({
    required this.id,
    required this.title,
    required this.type,
    this.isCompleted = false,
    this.completedDate,
  });

  ToDoTask copyWith({
    String? id,
    String? title,
    String? type,
    bool? isCompleted,
    String? completedDate,
  }) {
    return ToDoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'isCompleted': isCompleted,
        'completedDate': completedDate,
      };

  factory ToDoTask.fromJson(Map<String, dynamic> json) => ToDoTask(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedDate: json['completedDate'] as String?,
      );
}

class ToDoListNotifier extends Notifier<List<ToDoTask>> {
  static const String _key = 'todo_tasks_list';

  @override
  List<ToDoTask> build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final String? data = prefs.getString(_key);
    if (data != null) {
      try {
        final List decoded = json.decode(data) as List;
        return decoded.map((e) => ToDoTask.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPrefsProvider);
    final String encoded = json.encode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> addTask(String title, String type) async {
    final task = ToDoTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
    );
    state = [...state, task];
    await _save();
  }

  Future<void> toggleTask(String id) async {
    final today = _formatDate(DateTime.now());
    state = state.map((task) {
      if (task.id == id) {
        final nextVal = !task.isCompleted;
        if (nextVal) {
          ref.read(activityProvider.notifier).incrementActivity(today);
        } else if (task.completedDate != null) {
          ref.read(activityProvider.notifier).decrementActivity(task.completedDate!);
        }
        return task.copyWith(
          isCompleted: nextVal,
          completedDate: nextVal ? today : null,
        );
      }
      return task;
    }).toList();
    await _save();
  }

  Future<void> removeTask(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    if (task.isCompleted && task.completedDate != null) {
      await ref.read(activityProvider.notifier).decrementActivity(task.completedDate!);
    }
    state = state.where((t) => t.id != id).toList();
    await _save();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

final toDoListProvider = NotifierProvider<ToDoListNotifier, List<ToDoTask>>(
  ToDoListNotifier.new,
);

class ActivityNotifier extends Notifier<Map<String, int>> {
  static const String _key = 'study_activity_map';

  @override
  Map<String, int> build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final String? data = prefs.getString(_key);
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(data) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as int));
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_key, json.encode(state));
  }

  Future<void> incrementActivity(String dateStr) async {
    final newState = Map<String, int>.from(state);
    newState[dateStr] = (newState[dateStr] ?? 0) + 1;
    state = newState;
    await _save();
  }

  Future<void> decrementActivity(String dateStr) async {
    final newState = Map<String, int>.from(state);
    final val = newState[dateStr] ?? 0;
    if (val > 1) {
      newState[dateStr] = val - 1;
    } else {
      newState.remove(dateStr);
    }
    state = newState;
    await _save();
  }

  Future<void> recordTodayCompletion() async {
    final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    await incrementActivity(today);
  }

  Future<void> removeTodayCompletion() async {
    final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    await decrementActivity(today);
  }
}

final activityProvider = NotifierProvider<ActivityNotifier, Map<String, int>>(
  ActivityNotifier.new,
);

final streakProvider = Provider<int>((ref) {
  final activity = ref.watch(activityProvider);
  if (activity.isEmpty) return 0;

  int streak = 0;
  DateTime currentCheck = DateTime.now();
  String todayStr = _formatDate(currentCheck);

  // If there's activity today, start checking from today.
  // Otherwise, start checking from yesterday.
  if ((activity[todayStr] ?? 0) == 0) {
    currentCheck = currentCheck.subtract(const Duration(days: 1));
  }

  while (true) {
    final dateStr = _formatDate(currentCheck);
    if ((activity[dateStr] ?? 0) > 0) {
      streak++;
      currentCheck = currentCheck.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
});

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
