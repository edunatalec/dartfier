import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class ListenWhenPage extends StatefulWidget {
  const ListenWhenPage({super.key});

  @override
  State<ListenWhenPage> createState() => _ListenWhenPageState();
}

class _ListenWhenPageState extends State<ListenWhenPage> {
  final _count = Signal(0);
  late final _isEven = Computed(() => _count.value.isEven);
  final _changes = Signal(const <String>[]);

  late final Effect _countSubscription;
  late final Effect _paritySubscription;

  final _total = AsyncSignal<int>();
  final _awaited = Signal(const <String>[]);

  @override
  void initState() {
    super.initState();

    _countSubscription = _count.listen(
      (previous, next) => _logChange('count: $previous → $next'),
    );
    _paritySubscription = _isEven.listen(
      (previous, next) =>
          _logChange('parity: ${_parity(previous)} → ${_parity(next)}'),
    );
  }

  @override
  void dispose() {
    _paritySubscription.dispose();
    _countSubscription.dispose();
    _awaited.dispose();
    _total.dispose();
    _changes.dispose();
    _isEven.dispose();
    _count.dispose();

    super.dispose();
  }

  String _parity(bool isEven) => isEven ? 'even' : 'odd';

  void _logChange(String entry) {
    _changes.value = [..._changes.peek(), entry];
  }

  void _logAwaited(String entry) {
    _awaited.value = [..._awaited.peek(), entry];
  }

  void _onIncrementTap() {
    _count.update((current) => current + 1);
  }

  void _onSkipTwoTap() {
    _count.update((current) => current + 2);
  }

  void _onBurstTap() {
    _count.update((current) => current + 1);
    _count.update((current) => current + 1);
    _count.update((current) => current + 1);
  }

  Future<int> _fetchTotal() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return 42;
  }

  Future<void> _onAwaitDataTap() async {
    _logAwaited('run started — awaiting AsyncData');
    unawaited(_total.run(_fetchTotal));

    final AsyncValue<int> loaded = await _total.when(
      (value) => value is AsyncData<int>,
    );

    _logAwaited('when completed with ${loaded.valueOrNull}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('listen & when')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('listen remembers the previous value'),
            const SizedBox(height: 8),
            const InfoCard(
              'listen calls back with the previous and the next value, and '
              'returns the Effect behind it as the subscription handle. Being '
              'an Effect buys the hard parts: "Burst +3" writes three times in '
              'a row and logs a single change, from the value before the burst '
              'to the value after it. The parity subscription listens to a '
              'Computed and only logs when the derived value actually changes '
              '— "Skip 2" notifies it, but even stays even, so the spurious '
              'notification is filtered out.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Center(
                child: Text(
                  'count: ${_count.value} — ${_parity(_isEven.value)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Observer(
              (context) => EventLog(
                entries: _changes.value,
                emptyLabel: 'No change logged yet',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _onIncrementTap,
                  child: const Text('+1'),
                ),
                FilledButton.tonal(
                  onPressed: _onSkipTwoTap,
                  child: const Text('Skip 2'),
                ),
                FilledButton.tonal(
                  onPressed: _onBurstTap,
                  child: const Text('Burst +3'),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('when awaits a condition'),
            const SizedBox(height: 8),
            const InfoCard(
              'when completes a Future with the first value that satisfies a '
              'condition — the current value is checked first, so an '
              'already-satisfied condition completes immediately without '
              'subscribing to anything. Here a fetch starts and the handler '
              'simply awaits AsyncData, no listener bookkeeping in sight. '
              'There is no built-in timeout: wrap the call in Future.timeout '
              'when the condition may never be satisfied.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Center(
                child: Text('total: ${_total.value.valueOrNull ?? '—'}'),
              ),
            ),
            const SizedBox(height: 8),
            Observer(
              (context) => EventLog(
                entries: _awaited.value,
                emptyLabel: 'Nothing awaited yet',
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonal(
                onPressed: _onAwaitDataTap,
                child: const Text('Fetch and await AsyncData'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
