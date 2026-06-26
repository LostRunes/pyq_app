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
import 'package:focus_fox/features/settings/presentation/screens/about_screen.dart';
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
import 'package:focus_fox/features/utilities/presentation/screens/scientific_calculator_screen.dart';
import 'package:focus_fox/shared/presentation/transitions/parallax_page_route.dart';

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
        return ParallaxPageRoute(
          child: LoginScreen(
            showUsernameDialog: args?['showUsernameDialog'] ?? false,
          ),
          settings: settings,
        );
      case '/selection':
        return ParallaxPageRoute(
          child: const BranchYearSelectionScreen(),
          settings: settings,
        );
      case '/main_navigation':
        final args = settings.arguments as Map<String, dynamic>;
        return ParallaxPageRoute(
          child: MainNavigationScreen(
            branchId: args['branchId'],
            semester: args['semester'],
          ),
          settings: settings,
        );
      case '/subject_dashboard':
        final args = settings.arguments as Map<String, dynamic>;
        return ParallaxPageRoute(
          child: SubjectDashboardScreen(
            subject: args['subject'] as Subject,
          ),
          settings: settings,
        );
      case '/topics':
        final args = settings.arguments as Map<String, dynamic>;
        return ParallaxPageRoute(
          child: TopicListScreen(
            subjectId: args['subjectId'],
            subjectName: args['subjectName'] ?? 'Topics',
          ),
          settings: settings,
        );
      case '/questions':
        final args = settings.arguments as Map<String, dynamic>;
        return ParallaxPageRoute(
          child: QuestionListScreen(
            topicId: args['topicId'],
            topicName: args['topicName'] ?? 'Questions',
          ),
          settings: settings,
        );
      case '/question_detail':
        final args = settings.arguments as Map<String, dynamic>;
        return ParallaxPageRoute(
          child: QuestionDetailScreen(questionId: args['questionId']),
          settings: settings,
        );
      case '/profile':
        return ParallaxPageRoute(
          child: const ProfileScreen(),
          settings: settings,
        );
      case '/settings':
        return ParallaxPageRoute(
          child: const SettingsScreen(),
          settings: settings,
        );
      case '/about':
        return ParallaxPageRoute(
          child: const AboutScreen(),
          settings: settings,
        );
      case '/skulk_create':
        return ParallaxPageRoute(
          child: const CreateDoubtScreen(),
          settings: settings,
        );
      case '/skulk_whiteboard':
        return ParallaxPageRoute(
          child: const WhiteboardScreen(),
          settings: settings,
        );
      case '/skulk_detail':
        return ParallaxPageRoute(
          child: const DoubtDetailScreen(),
          settings: settings,
        );
      case '/skulk_notifications':
        return ParallaxPageRoute(
          child: const NotificationsScreen(),
          settings: settings,
        );
      case '/study-together':
        return ParallaxPageRoute(
          child: const StudyTogetherScreen(),
          settings: settings,
        );
      case '/study-together/chat':
        final room = settings.arguments as StudyRoom;
        return ParallaxPageRoute(
          child: StudyRoomChatScreen(room: room),
          settings: settings,
        );
      case '/youtube_resource':
        final args = settings.arguments as Map<String, dynamic>;
        return ParallaxPageRoute(
          child: YoutubeResourceScreen(
            url: args['url'] as String,
            title: args['title'] as String,
          ),
          settings: settings,
        );
      case '/upload_notes':
        return ParallaxPageRoute(
          child: const UploadNotesScreen(),
          settings: settings,
        );
      case '/gpa_calculator':
        return ParallaxPageRoute(
          child: const GpaCalculatorScreen(),
          settings: settings,
        );
      case '/scientific_calculator':
        return ParallaxPageRoute(
          child: const ScientificCalculatorScreen(),
          settings: settings,
        );
      case '/todo_dashboard':
        return ParallaxPageRoute(
          child: const ToDoDashboardScreen(),
          settings: settings,
        );
      case '/syllabus':
        return ParallaxPageRoute(
          child: const SyllabusScreen(),
          settings: settings,
        );
      case '/algo_code':
        return ParallaxPageRoute(
          child: const AlgoCodeScreen(),
          settings: settings,
        );
      case '/gate_prep':
        return ParallaxPageRoute(
          child: const GatePrepScreen(),
          settings: settings,
        );
      case '/focus_timer':
        return ParallaxPageRoute(
          child: const FocusTimerScreen(),
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
