import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../services/analytics_service.dart';
import 'router.dart';
import '../features/skulk/study_together/presentation/widgets/global_voice_overlay.dart';

/// A single global RouteObserver for the app.
/// Used by MainNavigationScreen to pause animations when a child route is active.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

class PyqApp extends ConsumerWidget {
  const PyqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Focus Fox',
      navigatorKey: AppRouter.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      navigatorObservers: [
        AnalyticsService.observer,
        appRouteObserver,
      ],
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      builder: (context, child) {
        return GlobalVoiceOverlayStack(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
