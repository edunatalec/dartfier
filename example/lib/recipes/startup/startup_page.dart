import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'startup_store.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  static const Duration _timeout = Duration(seconds: 2);

  final _store = StartupStore();
  final _log = Signal(const <String>[]);

  @override
  void dispose() {
    _log.dispose();
    _store.dispose();

    super.dispose();
  }

  void _logEntry(String entry) {
    _log.value = [..._log.peek(), entry];
  }

  void _onSignInTap() {
    _store.signOut();
    _logEntry('session started — the profile loads somewhere else');
    _store.startSession('@ana');
  }

  void _onSignOutTap() {
    _store.signOut();
    _logEntry('signed out — the profile is gone');
  }

  void _onToggleBackendTap() {
    _store.backendIsDown.value = !_store.backendIsDown.peek();
    _logEntry(
      _store.backendIsDown.peek()
          ? 'backend is down — the profile will never arrive'
          : 'backend is back up',
    );
  }

  Future<void> _onOpenHomeTap() async {
    final bool ready = _store.profile.peek() != null;

    _logEntry(
      ready
          ? 'open home — already loaded, when resolves immediately'
          : 'open home — waiting for the profile',
    );

    final Profile? profile = await _store.waitForProfile(timeout: _timeout);

    _logEntry(
      profile != null
          ? 'home opened for ${profile.handle}'
          : 'gave up after ${_timeout.inSeconds}s — staying on the splash',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup gate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('One actor emits, another awaits'),
              const SizedBox(height: 8),
              const InfoCard(
                'A splash that cannot route until the profile is in memory — '
                'except it is not the one loading it. "Sign in" only publishes '
                'an event on a plain broadcast Stream; a listener elsewhere '
                'answers it and writes Signal<Profile?> when the backend '
                'replies. "Open home" is the screen that needs the result and '
                'has nothing to await: no future to hold, no AsyncSignal, just '
                'a value that will show up.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Text(
                  'profile: ${_store.profile.value?.handle ?? '—'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Observer((context) => EventLog(entries: _log.value)),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _onSignInTap,
                    child: const Text('Sign in'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onOpenHomeTap,
                    child: const Text('Open home'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onSignOutTap,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
              const Divider(height: 48),
              const SectionTitle('Why when and not a Future'),
              const SizedBox(height: 8),
              const InfoCard.highlight(
                'when((value) => value != null) checks the current value with '
                'peek() first, so pressing "Open home" after the profile '
                'arrived resolves without subscribing to anything — press it '
                'twice and read the log. Pressed while the load is in flight, '
                'it waits for the one already running instead of starting a '
                'second one, which is what awaiting a load again would do. And '
                'because the condition is a predicate, not a state machine, '
                'the same call would work on a counter or a flag.',
              ),
              const SizedBox(height: 16),
              const InfoCard(
                'There is no built-in timeout: turn the backend off, sign in '
                'and open home — the profile never arrives and Future.timeout '
                'is what ends the wait. Note that it ends the wait, not the '
                'subscription: the underlying Effect stays until the condition '
                'is finally satisfied, so turning the backend back on and '
                'signing in again resolves it, harmlessly and late.',
              ),
              const SizedBox(height: 16),
              Center(
                child: Observer(
                  (context) => FilledButton.tonal(
                    onPressed: _onToggleBackendTap,
                    child: Text(
                      _store.backendIsDown.value
                          ? 'Bring the backend back'
                          : 'Take the backend down',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
