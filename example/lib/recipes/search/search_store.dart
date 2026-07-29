import 'dart:async';

import 'package:dartfier/dartfier.dart';

const _catalog = <String>[
  'Mango',
  'Mandarin',
  'Mangosteen',
  'Maple syrup',
  'Papaya',
  'Passion fruit',
  'Peach',
  'Pear',
  'Pineapple',
  'Plum',
  'Pomegranate',
  'Raspberry',
  'Strawberry',
  'Tangerine',
  'Watermelon',
];

class SearchStore {
  SearchStore() {
    _debounce = Effect((onCleanup) {
      final String term = _query.value.trim();

      if (term.isEmpty) return;

      final timer = Timer(
        debounceDelay,
        () => unawaited(_results.run(() => _fetch(term))),
      );

      onCleanup(timer.cancel);
    });
  }

  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration latency = Duration(milliseconds: 600);

  final _query = Signal('');
  final _results = AsyncSignal<List<String>>();
  final _fetches = Signal(0);

  late final _summary = Computed(
    () => switch (_results.value) {
      AsyncIdle() => 'Type to search',
      AsyncLoading(previous: null) => 'Searching…',
      AsyncLoading(:final List<String> previous?) =>
        'Searching… (still showing ${previous.length} from the last query)',
      AsyncData(:final List<String> value) when value.isEmpty => 'No matches',
      AsyncData(:final List<String> value) => '${value.length} matches',
      AsyncError(:final Object error) => 'Failed: $error',
    },
  );

  late final Effect _debounce;

  ReadonlySignal<String> get query => _query;
  ReadonlySignal<AsyncValue<List<String>>> get results => _results;
  ReadonlySignal<int> get fetches => _fetches;
  ReadonlySignal<String> get summary => _summary;

  void search(String term) {
    _query.value = term;
  }

  void dispose() {
    _debounce.dispose();
    _summary.dispose();
    _fetches.dispose();
    _results.dispose();
    _query.dispose();
  }

  Future<List<String>> _fetch(String term) async {
    _fetches.update((current) => current + 1);

    await Future<void>.delayed(latency);

    final String needle = term.toLowerCase();

    return _catalog
        .where((fruit) => fruit.toLowerCase().contains(needle))
        .toList();
  }
}
