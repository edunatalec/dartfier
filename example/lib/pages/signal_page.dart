import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class SignalPage extends StatefulWidget {
  const SignalPage({super.key});

  @override
  State<SignalPage> createState() => _SignalPageState();
}

class _SignalPageState extends State<SignalPage> {
  final _count = Signal(0);

  final _guarded = Signal(0);
  final _guardedNotifications = Signal(0);

  final _structuralItems = Signal(const [1, 2, 3], equals: listEquals);
  final _structuralNotifications = Signal(0);

  final _identityItems = Signal(const [1, 2, 3]);
  final _identityNotifications = Signal(0);

  final _mutable = Signal<List<int>>([1, 2, 3]);

  @override
  void initState() {
    super.initState();

    _guarded.addListener(_onGuardedNotified);
    _structuralItems.addListener(_onStructuralItemsNotified);
    _identityItems.addListener(_onIdentityItemsNotified);
  }

  @override
  void dispose() {
    _mutable.dispose();
    _identityItems.dispose();
    _identityNotifications.dispose();
    _structuralItems.dispose();
    _structuralNotifications.dispose();
    _guarded.dispose();
    _guardedNotifications.dispose();
    _count.dispose();

    super.dispose();
  }

  void _onGuardedNotified() {
    _guardedNotifications.value = _guardedNotifications.value + 1;
  }

  void _onStructuralItemsNotified() {
    _structuralNotifications.value = _structuralNotifications.value + 1;
  }

  void _onIdentityItemsNotified() {
    _identityNotifications.value = _identityNotifications.value + 1;
  }

  void _onDecrementTap() {
    _count.value = _count.value - 1;
  }

  void _onIncrementTap() {
    _count.update((current) => current + 1);
  }

  void _onSetFiveTap() {
    _guarded.value = 5;
  }

  void _onBumpGuardedTap() {
    _guarded.value = _guarded.value + 1;
  }

  void _onSetEqualListTap() {
    final List<int> next = [1, 2, 3];

    _structuralItems.value = next;
    _identityItems.value = next;
  }

  void _onAppendTap() {
    final List<int> current = _structuralItems.value;
    final List<int> next = [...current, current.length + 1];

    _structuralItems.value = next;
    _identityItems.value = next;
  }

  void _onMutateInPlaceTap() {
    _mutable.value.add(_mutable.value.length + 1);
  }

  void _onReassignTap() {
    _mutable.value = [..._mutable.value];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('A reactive value'),
            const SizedBox(height: 8),
            const InfoCard(
              'Signal(0) holds a value. Reading .value inside an Observer '
              'subscribes the widget; writing .value notifies it. No '
              'listenable lists, no setState. Minus writes .value directly; '
              'plus goes through update((current) => current + 1), which '
              'reads the current value with peek() before writing.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Text(
                'count: ${_count.value}',
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
                IconButton.filledTonal(
                  onPressed: _onDecrementTap,
                  icon: const Icon(Icons.remove),
                ),
                IconButton.filledTonal(
                  onPressed: _onIncrementTap,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('The equality guard'),
            const SizedBox(height: 8),
            const InfoCard(
              'A write whose new value is equal to the current one is '
              'swallowed: listeners are not notified. Press "Set 5" twice — '
              'the second press changes nothing, so the notification count '
              'stays put.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Text(
                'value: ${_guarded.value} — '
                'notifications: ${_guardedNotifications.value}',
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
                  onPressed: _onSetFiveTap,
                  child: const Text('Set 5'),
                ),
                FilledButton.tonal(
                  onPressed: _onBumpGuardedTap,
                  child: const Text('Increment'),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('Custom equals'),
            const SizedBox(height: 8),
            const InfoCard.highlight(
              'Two signals, same writes: one with equals: listEquals, the '
              'other with the default ==. "Set [1, 2, 3]" assigns a fresh list '
              'holding the same elements — listEquals judges it equal and '
              'swallows the write, while == compares instances and notifies. '
              '"Append" changes the elements, so both notify. List does not '
              'override ==, so without a custom equals the guard is identity: '
              'every reassignment notifies.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Column(
                children: [
                  Text(
                    'equals: listEquals — ${_structuralItems.value} — '
                    'notifications: ${_structuralNotifications.value}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'default == — ${_identityItems.value} — '
                    'notifications: ${_identityNotifications.value}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _onSetEqualListTap,
                  child: const Text('Set [1, 2, 3]'),
                ),
                FilledButton.tonal(
                  onPressed: _onAppendTap,
                  child: const Text('Append'),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('Mutating in place does nothing'),
            const SizedBox(height: 8),
            const InfoCard(
              'Exactly like ValueNotifier: a Signal notifies on assignment, '
              'not on what you do to the object it holds. Press "Mutate '
              '(.add)" a few times — the list below never changes, because '
              'the signal was never written to. Then press "Reassign" and '
              'every hidden mutation appears at once: they were always there, '
              'just invisible. Replace the collection instead: '
              'items.value = [...items.value, next].',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Text(
                'mutable: ${_mutable.value}',
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
                  onPressed: _onMutateInPlaceTap,
                  child: const Text('Mutate (.add)'),
                ),
                FilledButton.tonal(
                  onPressed: _onReassignTap,
                  child: const Text('Reassign'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
