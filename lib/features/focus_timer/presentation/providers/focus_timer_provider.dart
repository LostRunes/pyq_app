import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/push_notification_service.dart';

class FocusTimerState {
  final int durationSeconds;
  final int secondsRemaining;
  final bool isRunning;
  final bool hasStarted;
  final bool isCompleted;

  FocusTimerState({
    required this.durationSeconds,
    required this.secondsRemaining,
    required this.isRunning,
    required this.hasStarted,
    this.isCompleted = false,
  });

  FocusTimerState copyWith({
    int? durationSeconds,
    int? secondsRemaining,
    bool? isRunning,
    bool? hasStarted,
    bool? isCompleted,
  }) {
    return FocusTimerState(
      durationSeconds: durationSeconds ?? this.durationSeconds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      hasStarted: hasStarted ?? this.hasStarted,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class FocusTimerNotifier extends Notifier<FocusTimerState> {
  Timer? _timer;
  StreamSubscription<String>? _actionSubscription;

  @override
  FocusTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _actionSubscription?.cancel();
      PushNotificationService.cancelFocusTimerNotification();
    });

    // Listen to background notification controls (Pause / Resume / End Session)
    _actionSubscription?.cancel();
    _actionSubscription =
        PushNotificationService.focusTimerActions.stream.listen((action) {
      if (action == 'pause') {
        pause();
      } else if (action == 'resume') {
        resume();
      } else if (action == 'end') {
        endSession();
      }
    });

    return FocusTimerState(
      durationSeconds: 25 * 60,
      secondsRemaining: 25 * 60,
      isRunning: false,
      hasStarted: false,
    );
  }

  void start() {
    if (state.isRunning) return;
    SystemSound.play(SystemSoundType.click);

    _timer?.cancel();
    state = state.copyWith(
      hasStarted: true,
      isRunning: true,
      isCompleted: false,
    );

    // Show persistent notification immediately
    PushNotificationService.showFocusTimerNotification(
      secondsRemaining: state.secondsRemaining,
      durationSeconds: state.durationSeconds,
      isRunning: state.isRunning,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsRemaining > 0) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
        PushNotificationService.showFocusTimerNotification(
          secondsRemaining: state.secondsRemaining,
          durationSeconds: state.durationSeconds,
          isRunning: state.isRunning,
        );
      } else {
        _onComplete();
      }
    });
  }

  void pause() {
    if (!state.isRunning) return;
    SystemSound.play(SystemSoundType.click);
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    PushNotificationService.showFocusTimerNotification(
      secondsRemaining: state.secondsRemaining,
      durationSeconds: state.durationSeconds,
      isRunning: state.isRunning,
    );
  }

  void resume() {
    start();
  }

  void reset() {
    SystemSound.play(SystemSoundType.click);
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      secondsRemaining: state.durationSeconds,
      isCompleted: false,
    );
    PushNotificationService.showFocusTimerNotification(
      secondsRemaining: state.secondsRemaining,
      durationSeconds: state.durationSeconds,
      isRunning: state.isRunning,
    );
  }

  void endSession() {
    _timer?.cancel();
    PushNotificationService.cancelFocusTimerNotification();
    state = state.copyWith(
      isRunning: false,
      hasStarted: false,
      secondsRemaining: state.durationSeconds,
      isCompleted: false,
    );
  }

  void _onComplete() {
    _timer?.cancel();
    PushNotificationService.cancelFocusTimerNotification();
    PushNotificationService.showFocusTimerCompletionNotification();
    state = state.copyWith(
      isRunning: false,
      hasStarted: false,
      secondsRemaining: state.durationSeconds,
      isCompleted: true,
    );
  }

  void updateDuration(int minutes) {
    if (minutes < 1) minutes = 1;
    if (minutes > 360) minutes = 360;

    final seconds = minutes * 60;
    state = state.copyWith(
      durationSeconds: seconds,
      secondsRemaining: seconds,
    );
  }

  void clearCompletionFlag() {
    state = state.copyWith(isCompleted: false);
  }
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(
  FocusTimerNotifier.new,
);
