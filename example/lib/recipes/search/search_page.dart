import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'search_store.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _store = SearchStore();

  @override
  void dispose() {
    _store.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debounced search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('One Effect is the whole debounce'),
            const SizedBox(height: 8),
            const InfoCard(
              'The body reads the query, starts a 300ms Timer and registers '
              'its cancel as the cleanup. Every keystroke reruns the body, '
              'and a rerun begins by running the previous cleanup — so the '
              'pending timer dies before the new one is armed. That is the '
              'debounce, and it is why this is an Effect and not a listen: '
              'listen would hand over previous → next, which nobody here '
              'needs, and no place to cancel from. Type fast and watch the '
              'fetch counter: the letters are many, the request is one.',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search fruits',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _store.search,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Observer((context) => Text(_store.summary.value)),
                ),
                const SizedBox(width: 12),
                CountBadge(label: 'fetches', count: _store.fetches),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: Observer((context) {
                final AsyncValue<List<String>> results = _store.results.value;
                final List<String> items =
                    results.valueOrNull ?? const <String>[];

                return Column(
                  children: [
                    if (results.isLoading)
                      const LinearProgressIndicator()
                    else
                      const SizedBox(height: 4),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(child: Text('No results to show'))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.eco_outlined),
                                title: Text(items[index]),
                              ),
                            ),
                    ),
                  ],
                );
              }),
            ),
            const Divider(height: 48),
            const SectionTitle('The old list stays while the new one loads'),
            const SizedBox(height: 8),
            const InfoCard(
              'The results live in an AsyncSignal, so a refetch publishes '
              'AsyncLoading carrying the previous list: the screen shows a '
              'progress bar over the old matches instead of blanking out. '
              'And run is latest-wins — when a slow request finally answers '
              'after a newer one has already landed, its outcome is dropped, '
              'so the list can never jump back to an older query.',
            ),
            const SizedBox(height: 16),
            const InfoCard.highlight(
              'dartfier ships no debounce and no throttle on purpose: timing '
              'policy depends on what the effect is for — whether it can be '
              'cancelled, whether it must flush on submit, whether the first '
              'keystroke should fire immediately. Those are three lines at '
              'the call site, and they are right here to read.',
            ),
          ],
        ),
      ),
    );
  }
}
