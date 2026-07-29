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
import 'recipes/cart/cart_page.dart';
import 'recipes/gated_action/gated_action_page.dart';
import 'recipes/search/search_page.dart';
import 'recipes/session/session_page.dart';

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
    const apiTour = <_Example>[
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

    const recipes = <_Example>[
      _Example(
        title: 'Session events',
        subtitle: 'Why listen and not Effect — reacting to the transition',
        page: SessionPage(),
      ),
      _Example(
        title: 'Debounced search',
        subtitle: 'Why Effect and not listen — the cleanup is the debounce',
        page: SearchPage(),
      ),
      _Example(
        title: 'Checkout rules',
        subtitle: 'Computed holding business rules — shipping, coupon, total',
        page: CartPage(),
      ),
      _Example(
        title: 'Action with a prerequisite',
        subtitle: 'Why when — awaiting readiness inside a handler',
        page: GatedActionPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('dartfier Examples'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const _SectionHeader(
            title: 'API tour',
            subtitle: 'One page per feature, with the guarantees on screen',
          ),
          ...apiTour.map((example) => _ExampleTile(example)),
          const _SectionHeader(
            title: 'Real-world recipes',
            subtitle: 'Screens you would actually ship, and why each API',
          ),
          ...recipes.map((example) => _ExampleTile(example)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile(this.example);

  final _Example example;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
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
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
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
