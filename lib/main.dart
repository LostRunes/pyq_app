import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/branch_year_selection_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/topic_list_screen.dart';
import 'screens/question_list_screen.dart';
import 'screens/question_detail_screen.dart';
import 'screens/subject_dashboard_screen.dart';
import 'screens/youtube_resource_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'models/subject.dart';
import 'core/providers.dart';
import 'screens/upload_notes_screen.dart';
import 'screens/gpa_calculator_screen.dart';
import 'screens/syllabus_screen.dart';
import 'screens/algo_code_screen.dart';
import 'screens/gate_prep_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/skulk/presentation/screens/create_doubt_screen.dart';
import 'features/skulk/presentation/screens/doubt_detail_screen.dart';
import 'features/skulk/presentation/screens/notifications_screen.dart';
import 'features/skulk/study_together/presentation/screens/study_together_screen.dart';
import 'features/skulk/study_together/presentation/screens/study_room_chat_screen.dart';
import 'features/skulk/study_together/data/models/study_room.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/analytics_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_2_URL']!,
    anonKey: dotenv.env['SUPABASE_2_KEY']!,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
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
      title: 'Focus Fox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      navigatorObservers: [AnalyticsService.observer],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return LoginScreen(
            showUsernameDialog: args?['showUsernameDialog'] ?? false,
          );
        },
        '/selection': (context) => const BranchYearSelectionScreen(),
        '/main_navigation': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return MainNavigationScreen(
            branchId: args['branchId'],
            semester: args['semester'],
          );
        },
        '/subject_dashboard': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return SubjectDashboardScreen(subject: args['subject'] as Subject);
        },
        '/topics': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return TopicListScreen(
            subjectId: args['subjectId'],
            subjectName: args['subjectName'] ?? 'Topics',
          );
        },
        '/questions': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return QuestionListScreen(
            topicId: args['topicId'],
            topicName: args['topicName'] ?? 'Questions',
          );
        },
        '/question_detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return QuestionDetailScreen(questionId: args['questionId']);
        },
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/skulk_create': (context) => const CreateDoubtScreen(),
        '/skulk_detail': (context) => const DoubtDetailScreen(),
        '/skulk_notifications': (context) => const NotificationsScreen(),
        '/study-together': (context) => const StudyTogetherScreen(),
        '/study-together/chat': (context) {
          final room = ModalRoute.of(context)!.settings.arguments as StudyRoom;
          return StudyRoomChatScreen(room: room);
        },
        '/youtube_resource': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return YoutubeResourceScreen(
            url: args['url'] as String,
            title: args['title'] as String,
          );
        },
        '/upload_notes': (context) => const UploadNotesScreen(),
        '/gpa_calculator': (context) => const GpaCalculatorScreen(),
        '/syllabus': (context) => const SyllabusScreen(),
        '/algo_code': (context) => const AlgoCodeScreen(),
        '/gate_prep': (context) => const GatePrepScreen(),
        '/focus_timer': (context) => const FocusTimerScreen(),
      },
    );
  }
}
