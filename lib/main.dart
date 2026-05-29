import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/branch_year_selection_screen.dart';
import 'screens/subject_list_screen.dart';
import 'screens/topic_list_screen.dart';
import 'screens/question_list_screen.dart';
import 'screens/question_detail_screen.dart';
import 'screens/subject_dashboard_screen.dart';
import 'models/subject.dart';
import 'core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const PyqApp(),
    ),
  );
}

class PyqApp extends ConsumerWidget {
  const PyqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'PYQ App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const BranchYearSelectionScreen(),
        '/subjects': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SubjectListScreen(branchId: args['branchId'], yearId: args['yearId']);
        },
        '/subject_dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SubjectDashboardScreen(subject: args['subject'] as Subject);
        },
        '/topics': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TopicListScreen(
            subjectId: args['subjectId'],
            subjectName: args['subjectName'] ?? 'Topics',
          );
        },
        '/questions': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return QuestionListScreen(
            topicId: args['topicId'],
            topicName: args['topicName'] ?? 'Questions',
          );
        },
        '/question_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return QuestionDetailScreen(questionId: args['questionId']);
        },
      },
    );
  }
}
