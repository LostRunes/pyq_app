import 'package:flutter/material.dart';
import 'package:focus_fox/features/subjects/presentation/screens/branch_year_selection_screen.dart';
import 'package:focus_fox/features/auth/presentation/screens/main_navigation_screen.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/topic_list_screen.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/question_list_screen.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/question_detail_screen.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/subject_dashboard_screen.dart';
import 'package:focus_fox/features/pyqs/presentation/screens/youtube_resource_screen.dart';
import 'package:focus_fox/features/auth/presentation/screens/splash_screen.dart';
import 'package:focus_fox/features/profile/presentation/screens/profile_screen.dart';
import 'package:focus_fox/features/settings/presentation/screens/settings_screen.dart';
import 'package:focus_fox/features/auth/presentation/screens/login_screen.dart';
import 'package:focus_fox/features/pyqs/data/models/subject.dart';
import 'package:focus_fox/features/uploads/presentation/screens/upload_notes_screen.dart';
import 'package:focus_fox/features/utilities/presentation/screens/gpa_calculator_screen.dart';
import 'package:focus_fox/features/prep_zone/presentation/screens/syllabus_screen.dart';
import 'package:focus_fox/features/prep_zone/presentation/screens/algo_code_screen.dart';
import 'package:focus_fox/features/prep_zone/presentation/screens/gate_prep_screen.dart';
import 'package:focus_fox/features/focus_timer/presentation/screens/focus_timer_screen.dart';
import 'package:focus_fox/features/skulk/presentation/screens/create_doubt_screen.dart';
import 'package:focus_fox/features/skulk/presentation/screens/doubt_detail_screen.dart';
import 'package:focus_fox/features/skulk/presentation/screens/whiteboard_screen.dart';
import 'package:focus_fox/features/skulk/presentation/screens/notifications_screen.dart';
import 'package:focus_fox/features/skulk/study_together/presentation/screens/study_together_screen.dart';
import 'package:focus_fox/features/skulk/study_together/presentation/screens/study_room_chat_screen.dart';
import 'package:focus_fox/features/skulk/study_together/data/models/study_room.dart';
import 'package:focus_fox/features/utilities/presentation/screens/todo_dashboard_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name != null && settings.name!.startsWith('/skulk/doubt/')) {
      final doubtId = settings.name!.substring('/skulk/doubt/'.length);
      return MaterialPageRoute(
        builder: (_) => const DoubtDetailScreen(),
        settings: RouteSettings(
          name: '/skulk_detail',
          arguments: doubtId,
        ),
      );
    }

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case '/login':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(
            showUsernameDialog: args?['showUsernameDialog'] ?? false,
          ),
          settings: settings,
        );
      case '/selection':
        return MaterialPageRoute(
          builder: (_) => const BranchYearSelectionScreen(),
          settings: settings,
        );
      case '/main_navigation':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MainNavigationScreen(
            branchId: args['branchId'],
            semester: args['semester'],
          ),
          settings: settings,
        );
      case '/subject_dashboard':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => SubjectDashboardScreen(
            subject: args['subject'] as Subject,
          ),
          settings: settings,
        );
      case '/topics':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TopicListScreen(
            subjectId: args['subjectId'],
            subjectName: args['subjectName'] ?? 'Topics',
          ),
          settings: settings,
        );
      case '/questions':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => QuestionListScreen(
            topicId: args['topicId'],
            topicName: args['topicName'] ?? 'Questions',
          ),
          settings: settings,
        );
      case '/question_detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => QuestionDetailScreen(questionId: args['questionId']),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case '/skulk_create':
        return MaterialPageRoute(
          builder: (_) => const CreateDoubtScreen(),
          settings: settings,
        );
      case '/skulk_whiteboard':
        return MaterialPageRoute(
          builder: (_) => const WhiteboardScreen(),
          settings: settings,
        );
      case '/skulk_detail':
        return MaterialPageRoute(
          builder: (_) => const DoubtDetailScreen(),
          settings: settings,
        );
      case '/skulk_notifications':
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: settings,
        );
      case '/study-together':
        return MaterialPageRoute(
          builder: (_) => const StudyTogetherScreen(),
          settings: settings,
        );
      case '/study-together/chat':
        final room = settings.arguments as StudyRoom;
        return MaterialPageRoute(
          builder: (_) => StudyRoomChatScreen(room: room),
          settings: settings,
        );
      case '/youtube_resource':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => YoutubeResourceScreen(
            url: args['url'] as String,
            title: args['title'] as String,
          ),
          settings: settings,
        );
      case '/upload_notes':
        return MaterialPageRoute(
          builder: (_) => const UploadNotesScreen(),
          settings: settings,
        );
      case '/gpa_calculator':
        return MaterialPageRoute(
          builder: (_) => const GpaCalculatorScreen(),
          settings: settings,
        );
      case '/todo_dashboard':
        return MaterialPageRoute(
          builder: (_) => const ToDoDashboardScreen(),
          settings: settings,
        );
      case '/syllabus':
        return MaterialPageRoute(
          builder: (_) => const SyllabusScreen(),
          settings: settings,
        );
      case '/algo_code':
        return MaterialPageRoute(
          builder: (_) => const AlgoCodeScreen(),
          settings: settings,
        );
      case '/gate_prep':
        return MaterialPageRoute(
          builder: (_) => const GatePrepScreen(),
          settings: settings,
        );
      case '/focus_timer':
        return MaterialPageRoute(
          builder: (_) => const FocusTimerScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
