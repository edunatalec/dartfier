import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class AsyncSignalPage extends StatefulWidget {
  const AsyncSignalPage({super.key});

  @override
  State<AsyncSignalPage> createState() => _AsyncSignalPageState();
}

class _AsyncSignalPageState extends State<AsyncSignalPage> {
  final _quote = AsyncSignal<String>();
  int _fetches = 0;

  final _race = AsyncSignal<String>();
  final _raceLog = Signal(const <String>[]);

  @override
  void dispose() {
    _raceLog.dispose();
    _race.dispose();
    _quote.dispose();

    super.dispose();
  }

  Future<String> _fetchQuote() async {
    await Future.delayed(const Duration(milliseconds: 800));

    const quotes = [
      'Reactivity is reading a value and being told when it changes.',
      'Push dirtiness, pull computation.',
      'The best subscription is the one you never wrote.',
      'A spinner flash is a state you forgot to carry.',
    ];

    _fetches = _fetches + 1;

    return quotes[_fetches % quotes.length];
  }

  Future<String> _fetchFailing() async {
    await Future.delayed(const Duration(milliseconds: 800));

    throw StateError('server unreachable');
  }

  void _onFetchTap() {
    unawaited(_quote.run(_fetchQuote));
  }

  void _onFetchFailingTap() {
    unawaited(_quote.run(_fetchFailing));
  }

  void _log(String entry) {
    _raceLog.value = [..._raceLog.value, entry];
  }

  Future<String> _fetchSlow() async {
    await Future.delayed(const Duration(seconds: 2));

    return 'slow';
  }

  Future<String> _fetchFast() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return 'fast';
  }

  Future<void> _onRaceTap() async {
    _log('slow started');
    final Future<void> slowRun = _race.run(_fetchSlow);

    _log('fast started');
    final Future<void> fastRun = _race.run(_fetchFast);

    await fastRun;
    _log('published: ${_race.peek().valueOrNull}');

    await slowRun;
    _log('slow completed → dropped (value stays ${_race.peek().valueOrNull})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AsyncSignal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('idle → loading → data / error'),
            const SizedBox(height: 8),
            const InfoCard(
              'AsyncSignal<T> is a Signal<AsyncValue<T>>. It starts AsyncIdle, '
              'and run publishes AsyncLoading, then AsyncData or AsyncError. '
              'AsyncLoading and AsyncError carry the previous data, so a '
              'refetch keeps showing the old content instead of flashing a '
              'spinner — valueOrNull is the shortcut for the latest usable '
              'data.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Observer(
                (context) => switch (_quote.value) {
                  AsyncIdle() => const Center(
                    child: Text('Not requested yet — tap Fetch'),
                  ),
                  AsyncLoading(:final previous?) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(previous, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ),
                  AsyncLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  AsyncData(:final value) => Center(
                    child: Text(value, textAlign: TextAlign.center),
                  ),
                  AsyncError(:final error, :final previous?) => Center(
                    child: Text(
                      'failed: $error\nprevious: $previous',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AsyncError(:final error) => Center(
                    child: Text('failed: $error', textAlign: TextAlign.center),
                  ),
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                FilledButton.tonal(
                  onPressed: _onFetchTap,
                  child: const Text('Fetch'),
                ),
                FilledButton.tonal(
                  onPressed: _onFetchFailingTap,
                  child: const Text('Fetch failing'),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('Latest wins'),
            const SizedBox(height: 8),
            const InfoCard(
              'Starting a new run drops the outcome of any older one still in '
              'flight — success or failure alike. Below, a slow fetch starts '
              'first and a fast one right after: the fast result is published, '
              'and when the slow one finally completes it is discarded, so the '
              'UI never shows stale data out of order.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Text(
                'current: ${_race.value.valueOrNull ?? '—'}',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Observer((context) => EventLog(entries: _raceLog.value)),
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonal(
                onPressed: _onRaceTap,
                child: const Text('Start slow (2s) then fast (300ms)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
