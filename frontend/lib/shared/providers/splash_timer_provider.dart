import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tracks whether the minimum splash presentation window (2800ms) has elapsed.
// The router gates navigation away from splash until this is true AND auth resolves.
class _SplashTimerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void elapsed() => state = true;
}

final splashTimerProvider =
    NotifierProvider<_SplashTimerNotifier, bool>(_SplashTimerNotifier.new);
