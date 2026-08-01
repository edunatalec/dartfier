import 'dart:async';

import 'package:dartfier/dartfier.dart';

class Profile {
  const Profile(this.handle);

  final String handle;
}

class StartupStore {
  StartupStore() {
    _subscription = _sessionStarted.stream.listen(_onSessionStarted);
  }

  static const Duration backendLatency = Duration(milliseconds: 800);

  final _sessionStarted = StreamController<String>.broadcast();
  late final StreamSubscription<String> _subscription;

  final profile = Signal<Profile?>(null);
  final backendIsDown = Signal(false);

  void startSession(String handle) => _sessionStarted.add(handle);

  Future<Profile?> waitForProfile({
    Duration timeout = const Duration(seconds: 2),
  }) => profile
      .when((Profile? value) => value != null)
      .timeout(timeout, onTimeout: () => null);

  void signOut() {
    profile.value = null;
  }

  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_sessionStarted.close());
    backendIsDown.dispose();
    profile.dispose();
  }

  Future<void> _onSessionStarted(String handle) async {
    await Future<void>.delayed(backendLatency);

    if (backendIsDown.peek()) return;

    profile.value = Profile(handle);
  }
}
