import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class ComputedPage extends StatefulWidget {
  const ComputedPage({super.key});

  @override
  State<ComputedPage> createState() => _ComputedPageState();
}

class _ComputedPageState extends State<ComputedPage> {
  final _price = Signal(10.0);
  final _quantity = Signal(1);

  int _totalRuns = 0;

  late final _total = Computed(() {
    _totalRuns++;

    return _price.value * _quantity.value;
  });

  final _numbers = Signal(const <int>[]);

  late final _evens = Computed(
    () => _numbers.value.where((number) => number.isEven).toList(),
    equals: listEquals,
  );

  int _evensBuilds = 0;
  int _nextOdd = 1;
  int _nextEven = 2;

  @override
  void dispose() {
    _evens.dispose();
    _numbers.dispose();
    _total.dispose();
    _quantity.dispose();
    _price.dispose();

    super.dispose();
  }

  void _onPriceDecrementTap() {
    if (_price.value <= 0) return;

    _price.value = _price.value - 0.5;
  }

  void _onPriceIncrementTap() {
    _price.value = _price.value + 0.5;
  }

  void _onQuantityDecrementTap() {
    if (_quantity.value <= 0) return;

    _quantity.value = _quantity.value - 1;
  }

  void _onQuantityIncrementTap() {
    _quantity.value = _quantity.value + 1;
  }

  void _onRebuildTap() {
    setState(() {});
  }

  void _onAddOddTap() {
    _numbers.value = [..._numbers.value, _nextOdd];
    _nextOdd += 2;
  }

  void _onAddEvenTap() {
    _numbers.value = [..._numbers.value, _nextEven];
    _nextEven += 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Computed')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Derived values'),
            const SizedBox(height: 8),
            const InfoCard(
              'Computed(() => price.value * quantity.value) derives a value '
              'from any reactive read and recomputes when a dependency '
              'changes. Reads are always consistent: any read after any '
              'notification sees current state.',
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Text(
                'price: ${_price.value.toStringAsFixed(2)} × '
                'quantity: ${_quantity.value} = '
                '${_total.value.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                const Text('price'),
                IconButton.filledTonal(
                  onPressed: _onPriceDecrementTap,
                  icon: const Icon(Icons.remove),
                ),
                IconButton.filledTonal(
                  onPressed: _onPriceIncrementTap,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                const Text('quantity'),
                IconButton.filledTonal(
                  onPressed: _onQuantityDecrementTap,
                  icon: const Icon(Icons.remove),
                ),
                IconButton.filledTonal(
                  onPressed: _onQuantityIncrementTap,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('Lazy, cached, recomputed on demand'),
            const SizedBox(height: 8),
            const InfoCard(
              'Staleness first, notifications last: a write marks the graph '
              'stale, and only a Computed someone listens to resolves itself '
              'and notifies. Stepping price or quantity above runs the '
              'compute once per change, while extra rebuilds read the cache '
              '— "Rebuild page" leaves the run count untouched.',
            ),
            const SizedBox(height: 16),
            Observer((context) {
              final double total = _total.value;

              return Text(
                'total: ${total.toStringAsFixed(2)} — '
                'computed ran $_totalRuns times',
                textAlign: TextAlign.center,
              );
            }),
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonal(
                onPressed: _onRebuildTap,
                child: const Text('Rebuild page'),
              ),
            ),
            const Divider(height: 48),
            const SectionTitle('equals decides what counts as a change'),
            const SizedBox(height: 8),
            const InfoCard.highlight(
              'A Computed only notifies when its value actually changes, and '
              'equals: listEquals is what "changes" means here. "Add odd" '
              'writes a new list into the signal, the Computed recomputes and '
              'lands on an equal list — so nothing propagates and this '
              'section does not rebuild. "Add even" produces a genuinely '
              'different list and rebuilds it.',
            ),
            const SizedBox(height: 16),
            Observer((context) {
              final List<int> current = _evens.value;

              _evensBuilds++;

              return Text(
                'evens: $current — this section built $_evensBuilds times',
                textAlign: TextAlign.center,
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                FilledButton.tonal(
                  onPressed: _onAddOddTap,
                  child: const Text('Add odd'),
                ),
                FilledButton.tonal(
                  onPressed: _onAddEvenTap,
                  child: const Text('Add even'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
