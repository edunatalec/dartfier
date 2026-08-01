import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class ValueListenablePage extends StatefulWidget {
  const ValueListenablePage({super.key});

  @override
  State<ValueListenablePage> createState() => _ValueListenablePageState();
}

class _ValueListenablePageState extends State<ValueListenablePage> {
  final _count = Signal(0);

  final _first = Signal(0);
  final _second = Signal(0);
  late final _merged = Listenable.merge([_first, _second]);

  @override
  void dispose() {
    _second.dispose();
    _first.dispose();
    _count.dispose();

    super.dispose();
  }

  void _onIncrementTap() {
    _count.value = _count.value + 1;
  }

  void _onBumpFirstTap() {
    _first.value = _first.value + 1;
  }

  void _onBumpSecondTap() {
    _second.value = _second.value + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ValueListenable interop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Three builders, one Signal'),
              const SizedBox(height: 8),
              const InfoCard(
                'Signal is a ChangeNotifier that implements ValueListenable, '
                'so any Flutter API accepting a Listenable works without an '
                'adapter. The three builders below follow the same Signal — a '
                'codebase built on ValueNotifier can adopt dartfier one '
                'variable at a time.',
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Observer(
                    (context) => Text('Observer: ${_count.value}'),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: ValueListenableBuilder<int>(
                    valueListenable: _count,
                    builder: (context, value, child) =>
                        Text('ValueListenableBuilder: $value'),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: AnimatedBuilder(
                    animation: _count,
                    builder: (context, child) =>
                        Text('AnimatedBuilder: ${_count.value}'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: FilledButton.tonal(
                  onPressed: _onIncrementTap,
                  child: const Text('Increment'),
                ),
              ),
              const Divider(height: 48),
              const SectionTitle('Listenable.merge'),
              const SizedBox(height: 8),
              const InfoCard(
                'Signals slot into Listenable.merge like any other notifier, '
                'so a single AnimatedBuilder can follow several at once. '
                'Inside an Observer none of this plumbing is needed — '
                'auto-tracking already combines every read in the builder.',
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _merged,
                builder: (context, child) => Text(
                  '${_first.value} + ${_second.value} = '
                  '${_first.value + _second.value}',
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
                    onPressed: _onBumpFirstTap,
                    child: const Text('Bump first'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onBumpSecondTap,
                    child: const Text('Bump second'),
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
