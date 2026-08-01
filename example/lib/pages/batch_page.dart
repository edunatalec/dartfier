import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class BatchPage extends StatefulWidget {
  const BatchPage({super.key});

  @override
  State<BatchPage> createState() => _BatchPageState();
}

class _BatchPageState extends State<BatchPage> {
  final _first = Signal('A');
  final _second = Signal('B');
  late final _pair = Computed(() => '${_first.value}${_second.value}');

  final _observed = <String>[];

  final _query = Signal('shoes');
  final _category = Signal<String?>('sneakers');
  final _inStock = Signal(true);

  int _filterRuns = 0;
  late final _summary = Computed(() {
    _filterRuns++;

    return '${_query.value.isEmpty ? 'any' : _query.value} / '
        '${_category.value ?? 'any'} / '
        '${_inStock.value ? 'in stock' : 'any'}';
  });

  @override
  void initState() {
    super.initState();

    _pair.addListener(() => setState(() => _observed.add(_pair.value)));
  }

  @override
  void dispose() {
    _summary.dispose();
    _inStock.dispose();
    _category.dispose();
    _query.dispose();
    _pair.dispose();
    _second.dispose();
    _first.dispose();

    super.dispose();
  }

  void _onSwapLooseTap() {
    setState(_observed.clear);

    final String held = _first.peek();
    _first.value = _second.peek();
    _second.value = held;
  }

  void _onSwapBatchedTap() {
    setState(_observed.clear);

    batch(() {
      final String held = _first.peek();
      _first.value = _second.peek();
      _second.value = held;
    });
  }

  void _onClearLooseTap() {
    setState(() => _filterRuns = 0);

    _query.value = '';
    _category.value = null;
    _inStock.value = false;
  }

  void _onClearBatchedTap() {
    setState(() => _filterRuns = 0);

    batch(() {
      _query.value = '';
      _category.value = null;
      _inStock.value = false;
    });
  }

  void _onRestoreFiltersTap() {
    setState(() => _filterRuns = 0);

    batch(() {
      _query.value = 'shoes';
      _category.value = 'sneakers';
      _inStock.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('batch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('An unbatched group leaks its middle'),
              const SizedBox(height: 8),
              const InfoCard.highlight(
                'Swapping two signals passes through a state that never existed '
                'logically. "Swap loose" writes them one at a time and a raw '
                'listener on the Computed sees BB before BA. "Swap batched" '
                'notifies once, at the end — only the final value escapes.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Text(
                  'pair: ${_pair.value}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'listener observed: ${_observed.isEmpty ? '—' : _observed.join(' → ')}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _onSwapLooseTap,
                    child: const Text('Swap loose'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onSwapBatchedTap,
                    child: const Text('Swap batched'),
                  ),
                ],
              ),
              const Divider(height: 48),
              const SectionTitle('One reconciliation instead of three'),
              const SizedBox(height: 8),
              const InfoCard(
                'A Computed reconciles once per write. Clearing three filters '
                'loose runs the derivation three times to reach one result; '
                'inside a batch it runs once. Restore also batches, so the run '
                'count stays at one either way.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Text(
                  '${_summary.value} — derivation ran $_filterRuns times',
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
                    onPressed: _onClearLooseTap,
                    child: const Text('Clear loose'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onClearBatchedTap,
                    child: const Text('Clear batched'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onRestoreFiltersTap,
                    child: const Text('Restore'),
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
