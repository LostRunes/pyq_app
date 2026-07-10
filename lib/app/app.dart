import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../services/analytics_service.dart';
import 'router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/skulk/study_together/presentation/widgets/global_voice_overlay.dart';

/// A single global RouteObserver for the app.
/// Used by MainNavigationScreen to pause animations when a child route is active.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// Thin Riverpod listener that watches [themeModeProvider] and feeds the
/// value into the [MaterialApp] that lives one level above it in the tree.
/// Because this widget is a [ConsumerWidget] that wraps [MaterialApp] as its
/// ONLY child, Flutter's element-diffing keeps the [MaterialApp] element
/// alive across rebuilds — the Navigator and its entire route stack are
/// never torn down when the theme changes.
class PyqApp extends ConsumerWidget {
  const PyqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return _AppShell(themeMode: themeMode);
  }
}

/// The [MaterialApp] lives here, inside a [StatefulWidget], so that Flutter
/// can reconcile it across [PyqApp] rebuilds (same runtimeType, same key).
/// The [themeMode] parameter is simply passed down — it does NOT trigger a
/// full Navigator rebuild because Flutter only diffes what actually changed.
class _AppShell extends StatefulWidget {
  final ThemeMode themeMode;
  const _AppShell({required this.themeMode});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Fox',
      navigatorKey: AppRouter.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.themeMode,
      navigatorObservers: [
        AnalyticsService.observer,
        appRouteObserver,
      ],
      onGenerateRoute: AppRouter.generateRoute,
      home: const SplashScreen(),
      builder: (context, child) {
        return GlobalVoiceOverlayStack(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
