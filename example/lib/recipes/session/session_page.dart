import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'session_store.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final _store = SessionStore();
  final _effectLog = Signal(const <String>[]);

  late final Effect _effectWatcher;
  late final Effect _snackbars;

  @override
  void initState() {
    super.initState();

    _effectWatcher = Effect((_) {
      final Session session = _store.session.value;

      _effectLog.value = [..._effectLog.peek(), 'current: $session'];
    });

    _snackbars = _store.session.listen(_onSessionChanged);
  }

  @override
  void dispose() {
    _snackbars.dispose();
    _effectWatcher.dispose();
    _effectLog.dispose();
    _store.dispose();

    super.dispose();
  }

  void _onSessionChanged(Session previous, Session next) {
    if (!mounted) return;

    final String? message = switch ((previous, next)) {
      (SignedOut(), SignedIn(:final String user)) => 'Welcome, $user',
      (SignedIn(user: final String from), SignedIn(user: final String to)) =>
        'Switched from $from to $to — dropping $from cache',
      (SignedIn(), Expired()) => 'Session expired — sign in again',
      (_, SignedOut()) => 'Signed out — back to login',
      _ => null,
    };

    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _onSignInTap() {
    _store.signIn('ana');
  }

  void _onSwitchTap() {
    _store.signIn('bruno');
  }

  void _onExpireTap() {
    _store.expire();
  }

  void _onSignOutTap() {
    _store.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session events')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('One signal, two ways to react'),
              const SizedBox(height: 8),
              const InfoCard(
                'An auth session is state; a welcome snackbar, a redirect to '
                'login and an analytics event are reactions to the change. Both '
                'an Effect and a listen can watch this signal — the two logs '
                'below watch the very same one, and only one of them is right '
                'for the job.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Center(
                  child: Text(
                    '${_store.session.value}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _onSignInTap,
                    child: const Text('Sign in as ana'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onSwitchTap,
                    child: const Text('Switch to bruno'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onExpireTap,
                    child: const Text('Expire'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onSignOutTap,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
              const Divider(height: 48),
              const SectionTitle('Effect — runs on creation, sees only "now"'),
              const SizedBox(height: 8),
              const InfoCard(
                'An Effect exists to keep a resource in sync with the current '
                'state, so running on creation is the feature: the timer, the '
                'subscription or the cache has to exist before anything '
                'changes. As a session watcher that same trait is a bug — the '
                'log below already has an entry before anyone signed in, which '
                'in a real app means greeting the user on boot and routing to '
                'login while nobody has logged out. And on "Switch to bruno" it '
                'only ever sees bruno: the account whose cache should be '
                'dropped is exactly the value it does not have.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => EventLog(
                  entries: _effectLog.value,
                  emptyLabel: 'Nothing observed yet',
                ),
              ),
              const Divider(height: 48),
              const SectionTitle(
                'listen — runs on change, knows where it came '
                'from',
              ),
              const SizedBox(height: 8),
              const InfoCard.highlight(
                'listen never fires on creation and always carries previous → '
                'next, which is what every reaction on this screen actually '
                'needs: signedOut → signedIn is a welcome, signedIn → signedIn '
                'is an account switch, signedIn → expired is a re-login prompt. '
                'The snackbars come from a listen in the page, because showing '
                'one needs a context; this log comes from a listen in the '
                'store, where analytics belongs. Both are Effects underneath, '
                'so both cost one dispose() — the store disposes its own.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => EventLog(
                  entries: _store.analyticsLog.value,
                  emptyLabel: 'No transition yet',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
