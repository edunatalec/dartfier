import 'package:dartfier/dartfier.dart';

sealed class Session {
  const Session();
}

final class SignedOut extends Session {
  const SignedOut();

  @override
  bool operator ==(Object other) => other is SignedOut;

  @override
  int get hashCode => (SignedOut).hashCode;

  @override
  String toString() => 'signedOut';
}

final class SignedIn extends Session {
  const SignedIn(this.user);

  final String user;

  @override
  bool operator ==(Object other) => other is SignedIn && other.user == user;

  @override
  int get hashCode => Object.hash(SignedIn, user);

  @override
  String toString() => 'signedIn($user)';
}

final class Expired extends Session {
  const Expired(this.user);

  final String user;

  @override
  bool operator ==(Object other) => other is Expired && other.user == user;

  @override
  int get hashCode => Object.hash(Expired, user);

  @override
  String toString() => 'expired($user)';
}

class SessionStore {
  SessionStore() {
    _analytics = _session.listen(
      (Session previous, Session next) => _log('$previous → $next'),
    );
  }

  final _session = Signal<Session>(const SignedOut());
  final _analyticsLog = Signal(const <String>[]);

  late final Effect _analytics;

  ReadonlySignal<Session> get session => _session;
  ReadonlySignal<List<String>> get analyticsLog => _analyticsLog;

  void signIn(String user) {
    _session.value = SignedIn(user);
  }

  void expire() {
    if (_session.peek() case SignedIn(:final String user)) {
      _session.value = Expired(user);
    }
  }

  void signOut() {
    _session.value = const SignedOut();
  }

  void dispose() {
    _analytics.dispose();
    _analyticsLog.dispose();
    _session.dispose();
  }

  void _log(String entry) {
    _analyticsLog.value = [..._analyticsLog.peek(), entry];
  }
}
