import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class ReadonlySignalPage extends StatefulWidget {
  const ReadonlySignalPage({super.key});

  @override
  State<ReadonlySignalPage> createState() => _ReadonlySignalPageState();
}

class _ReadonlySignalPageState extends State<ReadonlySignalPage> {
  final _count = Signal(0);

  late final _doubled = Computed(() => _count.value * 2);

  @override
  void dispose() {
    _doubled.dispose();
    _count.dispose();

    super.dispose();
  }

  void _onIncrementTap() {
    _count.value = _count.value + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReadonlySignal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Reading without writing'),
              const SizedBox(height: 8),
              const InfoCard(
                'Expose a value as ReadonlySignal to hand consumers reading '
                'and listening without the setter. Signal and Computed both '
                'implement it, so either fits where one is asked for — the '
                'natural parameter type for a leaf widget. CountBadge, in '
                'widgets/count_badge.dart of this app, declares its field as '
                'ReadonlySignal<int> and takes both below.',
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  CountBadge(label: 'signal', count: _count),
                  CountBadge(label: 'computed', count: _doubled),
                  IconButton.filledTonal(
                    onPressed: _onIncrementTap,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const Divider(height: 48),
              const SectionTitle('Sealed to the package'),
              const SizedBox(height: 8),
              const InfoCard.highlight(
                'The interface is abstract final and the concrete classes are '
                'base: implementing ReadonlySignal outside dartfier is a '
                'compile error. A ReadonlySignal is therefore always a real '
                'Signal or Computed underneath, so auto-tracking is guaranteed '
                'by construction. In tests, the stand-in is a real Signal.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Text(
                  '_count is ${_count.runtimeType} (${_count.value}) — '
                  '_doubled is ${_doubled.runtimeType} (${_doubled.value})',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
