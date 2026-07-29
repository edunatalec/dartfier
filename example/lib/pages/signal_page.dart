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

  final _items = Signal(const [1, 2, 3], equals: listEquals);
  final _itemsNotifications = Signal(0);

  @override
  void initState() {
    super.initState();

    _guarded.addListener(_onGuardedNotified);
    _items.addListener(_onItemsNotified);
  }

  @override
  void dispose() {
    _items.dispose();
    _itemsNotifications.dispose();
    _guarded.dispose();
    _guardedNotifications.dispose();
    _count.dispose();

    super.dispose();
  }

  void _onGuardedNotified() {
    _guardedNotifications.value = _guardedNotifications.value + 1;
  }

  void _onItemsNotified() {
    _itemsNotifications.value = _itemsNotifications.value + 1;
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
    _items.value = [1, 2, 3];
  }

  void _onAppendTap() {
    _items.value = [..._items.value, _items.value.length + 1];
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
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
            const InfoCard(
              'Signal([1, 2, 3], equals: listEquals) replaces == in the '
              'guard. Setting a fresh but element-equal list is swallowed; '
              'appending notifies. This is the supported pattern for '
              'collections: immutable snapshots plus a custom equals.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Text(
                'items: ${_items.value} — '
                'notifications: ${_itemsNotifications.value}',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
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
          ],
        ),
      ),
    );
  }
}
