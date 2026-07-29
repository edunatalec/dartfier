import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class ObserverPage extends StatefulWidget {
  const ObserverPage({super.key});

  @override
  State<ObserverPage> createState() => _ObserverPageState();
}

class _ObserverPageState extends State<ObserverPage> {
  final _showDetails = Signal(false);
  final _summary = Signal(0);
  final _details = Signal(0);
  int _builds = 0;

  final _outer = Signal(0);
  final _inner = Signal(0);
  int _outerBuilds = 0;
  int _innerBuilds = 0;

  final _withChildCount = Signal(0);

  final _focus = FocusNode();
  final _query = Signal('');

  @override
  void dispose() {
    _focus.dispose();
    _query.dispose();
    _outer.dispose();
    _inner.dispose();
    _withChildCount.dispose();
    _showDetails.dispose();
    _summary.dispose();
    _details.dispose();

    super.dispose();
  }

  void _onShowDetailsChanged(bool value) {
    _showDetails.value = value;
  }

  void _onMutateSummaryTap() {
    _summary.value = _summary.value + 1;
  }

  void _onMutateDetailsTap() {
    _details.value = _details.value + 1;
  }

  void _onMutateOuterTap() {
    _outer.value = _outer.value + 1;
  }

  void _onMutateInnerTap() {
    _inner.value = _inner.value + 1;
  }

  void _onIncrementTap() {
    _withChildCount.value = _withChildCount.value + 1;
  }

  void _onQueryChanged(String value) {
    _query.value = value;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Observer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Dependencies are rediscovered every build'),
            const SizedBox(height: 8),
            const InfoCard(
              'The Observer builder runs under tracking on every build, so '
              'dependencies are rediscovered each time. With details hidden '
              'the builder reads the toggle and the summary signal only — '
              '"Mutate details" then changes a value the observer dropped on '
              'its last retracking, and the build count stays put.',
            ),
            const SizedBox(height: 16),
            Observer((context) {
              _builds++;

              final bool showDetails = _showDetails.value;
              final String label = showDetails ? 'details' : 'summary';
              final int shown = showDetails ? _details.value : _summary.value;

              return Text(
                '$label: $shown — builds: $_builds',
                textAlign: TextAlign.center,
              );
            }),
            const SizedBox(height: 8),
            Observer(
              (context) => SwitchListTile(
                title: const Text('Show details'),
                value: _showDetails.value,
                onChanged: _onShowDetailsChanged,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _onMutateSummaryTap,
                  child: const Text('Mutate summary'),
                ),
                FilledButton.tonal(
                  onPressed: _onMutateDetailsTap,
                  child: const Text('Mutate details'),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('Nested observers rebuild independently'),
            const SizedBox(height: 8),
            const InfoCard(
              'Each Observer keeps its own dependency set: the inner builder '
              'runs under its own tracking scope, so its reads never leak to '
              'the outer one. "Mutate inner" rebuilds only the inner '
              'observer. "Mutate outer" rebuilds the outer one — and the '
              'inner rebuilds with it, plain Flutter: the outer builder '
              'recreates the inner widget on every build.',
            ),
            const SizedBox(height: 16),
            Observer((context) {
              _outerBuilds++;

              return Column(
                children: [
                  Text(
                    'outer: ${_outer.value} — builds: $_outerBuilds',
                    textAlign: TextAlign.center,
                  ),
                  Observer((context) {
                    _innerBuilds++;

                    return Text(
                      'inner: ${_inner.value} — builds: $_innerBuilds',
                      textAlign: TextAlign.center,
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _onMutateOuterTap,
                  child: const Text('Mutate outer'),
                ),
                FilledButton.tonal(
                  onPressed: _onMutateInnerTap,
                  child: const Text('Mutate inner'),
                ),
              ],
            ),
            const Divider(height: 48),
            const SectionTitle('withChild keeps static subtrees out'),
            const SizedBox(height: 8),
            const InfoCard(
              'Observer.withChild builds the child subtree once and hands '
              'the same instance back to the builder on every rebuild. Only '
              'the counter text is rebuilt; the styled box below it is '
              'constructed a single time.',
            ),
            const SizedBox(height: 16),
            Observer.withChild(
              builder: (context, child) => Column(
                children: [
                  Text(
                    'count: ${_withChildCount.value}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  child!,
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.secondaryContainer,
                ),
                child: Text(
                  'static child — built once',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
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
            const SectionTitle('Foreign listenables'),
            const SizedBox(height: 8),
            const InfoCard(
              'A foreign Listenable — a FocusNode, a ScrollController — is '
              'invisible to auto-tracking: only Signal and Computed reads '
              'subscribe. Passing it through listenables subscribes the '
              'observer manually, alongside the tracked reads. In debug '
              'mode, an Observer that tracks nothing and lists no '
              'listenables throws a FlutterError.',
            ),
            const SizedBox(height: 16),
            TextField(
              focusNode: _focus,
              decoration: const InputDecoration(
                labelText: 'Query',
                border: OutlineInputBorder(),
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 16),
            Observer(
              (context) => Text(
                _focus.hasFocus
                    ? 'typing: ${_query.value}'
                    : 'not focused — tap the field',
                textAlign: TextAlign.center,
              ),
              listenables: [_focus],
            ),
          ],
        ),
      ),
    );
  }
}
