import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class UntrackedPeekPage extends StatefulWidget {
  const UntrackedPeekPage({super.key});

  @override
  State<UntrackedPeekPage> createState() => _UntrackedPeekPageState();
}

class _UntrackedPeekPageState extends State<UntrackedPeekPage> {
  final _tracked = Signal(0);
  final _ignored = Signal(0);
  int _builds = 0;

  final _base = Signal(0);
  final _offset = Signal(100);
  late final _result = Computed(() => _base.value + _offset.peek());

  @override
  void dispose() {
    _result.dispose();
    _offset.dispose();
    _base.dispose();
    _ignored.dispose();
    _tracked.dispose();

    super.dispose();
  }

  void _onBumpTrackedTap() {
    _tracked.value = _tracked.value + 1;
  }

  void _onBumpIgnoredTap() {
    _ignored.value = _ignored.value + 1;
  }

  void _onBumpBaseTap() {
    _base.value = _base.value + 1;
  }

  void _onBumpOffsetTap() {
    _offset.value = _offset.value + 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('untracked & peek')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('untracked suspends a block'),
              const SizedBox(height: 8),
              const InfoCard(
                'untracked(fn) runs the block with dependency tracking '
                'suspended, so reads inside it never become dependencies of '
                'the Observer. "Bump ignored" changes the value but triggers '
                'no rebuild; the next "Bump tracked" rebuild reveals whatever '
                'the ignored signal accumulated in the meantime.',
              ),
              const SizedBox(height: 16),
              Observer((context) {
                _builds++;

                final int ignored = untracked(() => _ignored.value);

                return Text(
                  'tracked: ${_tracked.value} — ignored: $ignored — '
                  'builds: $_builds',
                  textAlign: TextAlign.center,
                );
              }),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _onBumpTrackedTap,
                    child: const Text('Bump tracked'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onBumpIgnoredTap,
                    child: const Text('Bump ignored'),
                  ),
                ],
              ),
              const Divider(height: 48),
              const SectionTitle('peek reads one value'),
              const SizedBox(height: 8),
              const InfoCard(
                'peek() is untracked for a single read: it returns the current '
                'value of one Signal or Computed without registering a '
                'dependency. This Computed reads the base reactively and the '
                'offset via peek(), so "Bump offset" never recomputes — the '
                'result stays put until "Bump base" recomputes and absorbs the '
                'accumulated offset.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Text(
                  'base: ${_base.value} — offset (peeked): ${_offset.peek()} — '
                  'result: ${_result.value}',
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
                    onPressed: _onBumpBaseTap,
                    child: const Text('Bump base'),
                  ),
                  FilledButton.tonal(
                    onPressed: _onBumpOffsetTap,
                    child: const Text('Bump offset'),
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
