import 'package:flutter/material.dart';

import 'pages/async_signal_page.dart';
import 'pages/computed_page.dart';
import 'pages/effect_page.dart';
import 'pages/listen_when_page.dart';
import 'pages/observer_page.dart';
import 'pages/readonly_signal_page.dart';
import 'pages/signal_page.dart';
import 'pages/untracked_peek_page.dart';
import 'pages/value_listenable_page.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dartfier Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const examples = <_Example>[
      _Example(
        title: 'Signal',
        subtitle: 'A reactive value — writes notify, guarded by equality',
        page: SignalPage(),
      ),
      _Example(
        title: 'Computed',
        subtitle: 'Lazy derived values — cached, recomputed on demand',
        page: ComputedPage(),
      ),
      _Example(
        title: 'ReadonlySignal',
        subtitle: 'The read-only supertype — leaf widgets read without writing',
        page: ReadonlySignalPage(),
      ),
      _Example(
        title: 'Effect',
        subtitle: 'Reactive side effects — cleanup registrar, coalesced reruns',
        page: EffectPage(),
      ),
      _Example(
        title: 'Observer',
        subtitle: 'Auto-tracking widget — retracking, withChild, listenables',
        page: ObserverPage(),
      ),
      _Example(
        title: 'AsyncSignal',
        subtitle: 'Async as a synchronous value — idle, loading, data, error',
        page: AsyncSignalPage(),
      ),
      _Example(
        title: 'listen & when',
        subtitle: 'Side effects on change — previous → next, awaited condition',
        page: ListenWhenPage(),
      ),
      _Example(
        title: 'untracked & peek',
        subtitle: 'Escape hatches — reading without subscribing',
        page: UntrackedPeekPage(),
      ),
      _Example(
        title: 'ValueListenable interop',
        subtitle: 'One Signal driving vanilla Flutter builders',
        page: ValueListenablePage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('dartfier Examples'), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: examples.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final _Example example = examples[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(example.title),
            subtitle: Text(example.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => example.page));
            },
          );
        },
      ),
    );
  }
}

class _Example {
  const _Example({
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final String title;
  final String subtitle;
  final Widget page;
}
