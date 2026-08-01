import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class EffectPage extends StatefulWidget {
  const EffectPage({super.key});

  @override
  State<EffectPage> createState() => _EffectPageState();
}

class _EffectPageState extends State<EffectPage> {
  final _period = Signal(const Duration(seconds: 1));
  final _log = Signal(const <String>[]);
  final _runs = Signal(0);

  int _ticks = 0;
  Effect? _ticker;

  @override
  void initState() {
    super.initState();

    _createTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _runs.dispose();
    _log.dispose();
    _period.dispose();

    super.dispose();
  }

  void _createTicker() {
    _ticker = Effect((onCleanup) {
      _runs.value = _runs.peek() + 1;

      final Duration period = _period.value;
      final timer = Timer.periodic(period, (_) {
        _ticks += 1;
        _log.value = [
          ..._log.value,
          'tick $_ticks (period ${period.inMilliseconds}ms)',
        ];
      });

      _log.value = [..._log.peek(), 'started ${period.inMilliseconds}ms timer'];

      onCleanup(() {
        timer.cancel();
        _log.value = [
          ..._log.value,
          'cleanup: cancelled ${period.inMilliseconds}ms timer',
        ];
      });
    });
  }

  void _onPeriodChanged(Set<Duration> selection) {
    _period.value = selection.first;
  }

  void _onBurstTap() {
    _period.value = const Duration(milliseconds: 500);
    _period.value = const Duration(seconds: 2);
  }

  void _onRoundTripTap() {
    final Duration period = _period.peek();

    _period.value = period * 2;
    _period.value = period;
  }

  void _onRoundTripBatchedTap() {
    final Duration period = _period.peek();

    batch(() {
      _period.value = period * 2;
      _period.value = period;
    });
  }

  void _onDisposeTap() {
    _ticker?.dispose();
    _ticker = null;
  }

  void _onRecreateTap() {
    if (_ticker != null) return;

    _createTicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Effect')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('A ticker with cleanup'),
              const SizedBox(height: 8),
              const InfoCard(
                'Effect runs its body synchronously on creation and reruns '
                'when a value it read changes. This one reads the period '
                'signal, starts a Timer.periodic, and registers onCleanup to '
                'cancel it — cleanups run in reverse order before every rerun '
                'and on dispose(). The body appends to the log through peek(): '
                'an effect must never read a signal it writes, or every rerun '
                'schedules the next one — after 100 consecutive self-triggered '
                'reruns the effect disposes itself and throws a StateError.',
              ),
              const SizedBox(height: 16),
              Observer((context) => EventLog(entries: _log.value)),
              const SizedBox(height: 8),
              Observer(
                (context) => Center(
                  child: SegmentedButton<Duration>(
                    segments: const [
                      ButtonSegment(
                        value: Duration(milliseconds: 500),
                        label: Text('500ms'),
                      ),
                      ButtonSegment(
                        value: Duration(seconds: 1),
                        label: Text('1s'),
                      ),
                      ButtonSegment(
                        value: Duration(seconds: 2),
                        label: Text('2s'),
                      ),
                    ],
                    selected: {_period.value},
                    onSelectionChanged: _onPeriodChanged,
                  ),
                ),
              ),
              const Divider(height: 48),
              const SectionTitle('Reruns coalesce per microtask'),
              const SizedBox(height: 8),
              const InfoCard(
                'Reruns are scheduled through the microtask queue, so a burst '
                'of synchronous writes produces a single rerun reading '
                'consistent state. This button writes the period twice back to '
                'back — the log shows one cleanup and one restart, not two, '
                'and the effect only ever sees the final value.',
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: _onBurstTap,
                  child: const Text('Burst: 500ms then 2s'),
                ),
              ),
              const Divider(height: 48),
              const SectionTitle('Coalescing groups, batch decides'),
              const SizedBox(height: 8),
              const InfoCard(
                'Coalescing answers how many times the effect runs, never '
                'whether it should run at all. "Round trip" doubles the period '
                'and puts the original back in the same turn: the first write '
                'already scheduled the rerun, so the count below moves and the '
                'effect rebuilds an identical timer — scroll up and the log '
                'shows a cleanup and a restart on the same period. Inside '
                'batch the guard covers the group, the value ends where it '
                'started, and nobody is notified: the count holds and the log '
                'stays untouched.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Text(
                  'effect runs: ${_runs.value}',
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
                    onPressed: _onRoundTripTap,
                    child: const Text('Round trip'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onRoundTripBatchedTap,
                    child: const Text('Round trip (batched)'),
                  ),
                ],
              ),
              const Divider(height: 48),
              const SectionTitle('Dispose is yours'),
              const SizedBox(height: 8),
              const InfoCard(
                'Whoever creates an Effect disposes it — nothing happens '
                'automatically. dispose() runs the pending cleanups, so the '
                'log shows the final cancel, and any scheduled rerun is '
                'dropped. Recreate builds a fresh Effect, which runs its first '
                'body synchronously and starts ticking again.',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  FilledButton.tonal(
                    onPressed: _onDisposeTap,
                    child: const Text('Dispose'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onRecreateTap,
                    child: const Text('Recreate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
