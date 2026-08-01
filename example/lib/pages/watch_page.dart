import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class WatchPage extends StatefulWidget {
  const WatchPage({super.key});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  final _user = Signal('ana');
  final _premium = Signal(false);
  final _log = Signal(const <String>[]);

  late final Watch<(String, bool)> _watcher;

  @override
  void initState() {
    super.initState();

    _watcher = Watch(() => (_user.value, _premium.value), _onPairChanged);
  }

  @override
  void dispose() {
    _watcher.dispose();
    _log.dispose();
    _premium.dispose();
    _user.dispose();

    super.dispose();
  }

  void _onPairChanged((String, bool) previous, (String, bool) next) {
    _log.value = [..._log.peek(), '$previous -> $next'];
  }

  void _onSwitchUserTap() {
    _user.value = _user.peek() == 'ana' ? 'bruno' : 'ana';
  }

  void _onTogglePremiumTap() {
    _premium.value = !_premium.peek();
  }

  void _onRoundTripTap() {
    final String user = _user.peek();

    _user.value = user == 'ana' ? 'bruno' : 'ana';
    _user.value = user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('One expression, every signal it reads'),
              const SizedBox(height: 8),
              const InfoCard(
                'Watch(() => (user.value, premium.value), onChange) runs the '
                'tracking function under tracking, so both signals become '
                'dependencies and the callback receives the previous and the '
                'next record. A record is what carries several values at once: '
                'records compare structurally, so any component changing fires '
                'the callback.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Text(
                  'current: (${_user.value}, ${_premium.value})',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _onSwitchUserTap,
                    child: const Text('Switch user'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onTogglePremiumTap,
                    child: const Text('Toggle premium'),
                  ),
                ],
              ),
              const Divider(height: 48),
              const SectionTitle('Nothing on creation'),
              const SizedBox(height: 8),
              const InfoCard.highlight(
                'The log below is empty when this page opens: the first run '
                'only captures the current value, so the callback never fires '
                'for state that was already there. That is the whole '
                'difference from Effect, whose body runs on creation — reach '
                'for Watch to react to a transition, and for Effect to bring '
                'something in sync with the state as it is now.',
              ),
              const SizedBox(height: 16),
              Observer((context) => EventLog(entries: _log.value)),
              const Divider(height: 48),
              const SectionTitle('A round trip is not a change'),
              const SizedBox(height: 8),
              const InfoCard(
                'Watch compares the result of the tracking function against '
                'the previous one, and reruns coalesce per microtask. "Round '
                'trip" switches the user and switches back in the same turn: '
                'the record ends where it started, so the callback is not '
                'called and the log stays untouched — no batch needed.',
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: _onRoundTripTap,
                  child: const Text('Round trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
