import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'gated_action_store.dart';

class GatedActionPage extends StatefulWidget {
  const GatedActionPage({super.key});

  @override
  State<GatedActionPage> createState() => _GatedActionPageState();
}

class _GatedActionPageState extends State<GatedActionPage> {
  static const Duration _shareTimeout = Duration(seconds: 3);

  final _store = GatedActionStore();
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

  void _onLoadTap() {
    _logEntry('loading the profile');
    unawaited(_store.load());
  }

  void _onBreakTap() {
    _logEntry('loading from a broken backend');
    unawaited(_store.loadFromBrokenBackend());
  }

  Future<void> _onShareTap() async {
    final bool alreadyLoaded = _store.profile.peek() is AsyncData<Profile>;

    _logEntry(
      alreadyLoaded
          ? 'share tapped — already loaded, when resolves immediately'
          : 'share tapped — awaiting the profile',
    );

    try {
      final AsyncValue<Profile> loaded = await _store.profile
          .when((value) => value is AsyncData<Profile>)
          .timeout(_shareTimeout);

      if (loaded case AsyncData(value: final Profile profile)) {
        _logEntry('shared ${profile.handle}');
      }
    } on TimeoutException {
      _logEntry('gave up after ${_shareTimeout.inSeconds}s — nothing shared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Action with a prerequisite')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Share needs a profile that may not be there'),
            const SizedBox(height: 8),
            const InfoCard(
              'The user can tap Share while the profile is still in flight. '
              'With when, the handler stays a plain async function: await the '
              'condition, then act. The alternative is bookkeeping — create a '
              'subscription, hold the handle, cancel it inside the callback, '
              'and split one action into two halves that have to find each '
              'other again.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Center(
                child: Text(switch (_store.profile.value) {
                  AsyncIdle() => 'profile: not requested',
                  AsyncLoading() => 'profile: loading…',
                  AsyncData(value: final Profile profile) =>
                    'profile: ${profile.name} (${profile.handle})',
                  AsyncError(:final Object error) =>
                    'profile: failed — '
                        '$error',
                }, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _onLoadTap,
                  child: const Text('Load profile'),
                ),
                FilledButton.tonal(
                  onPressed: _onBreakTap,
                  child: const Text('Break the backend'),
                ),
                FilledButton(
                  onPressed: _onShareTap,
                  child: const Text('Share profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => EventLog(
                entries: _log.value,
                emptyLabel: 'Nothing happened yet',
              ),
            ),
            const Divider(height: 48),
            const SectionTitle('Already satisfied means already done'),
            const SizedBox(height: 8),
            const InfoCard(
              'when checks the current value first, with peek(): a profile '
              'that is already loaded completes the future on the spot, '
              'without subscribing to anything — so awaiting it inside a '
              'tracked scope never subscribes that scope by accident. Tap '
              'Share twice after the profile lands and the log says so.',
            ),
            const SizedBox(height: 16),
            const SectionTitle('A condition that never comes true'),
            const SizedBox(height: 8),
            const InfoCard.highlight(
              'There is no built-in timeout, and that is deliberate: a signal '
              'is state, not a stream, and nothing guarantees the state ever '
              'satisfies the condition. Break the backend and tap Share — the '
              'profile settles on AsyncError, which is not AsyncData, so the '
              'future would wait forever. Future.timeout is what brings the '
              'handler back, and the log shows it giving up.',
            ),
          ],
        ),
      ),
    );
  }
}
