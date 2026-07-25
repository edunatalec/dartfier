import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Minimal app exercising every dartfier primitive.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CounterPage());
  }
}

/// Counter page driven by signals.
class CounterPage extends StatefulWidget {
  /// Creates the counter page.
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final Signal<int> count = Signal(0);
  final Signal<List<int>> history = Signal(<int>[], equals: listEquals);

  late final Computed<int> doubled = Computed(() => count.value * 2);

  late final Effect logger;

  @override
  void initState() {
    super.initState();

    logger = Effect((onCleanup) {
      final int seen = count.value;
      final int recorded = untracked(() => history.value).length;
      debugPrint('count: $seen (doubled: ${doubled.peek()}, $recorded moves)');

      onCleanup(() => debugPrint('leaving $seen'));
    });
  }

  @override
  void dispose() {
    logger.dispose();
    doubled.dispose();
    history.dispose();
    count.dispose();

    super.dispose();
  }

  void _onIncrementTap() {
    count.value = count.value + 1;
    history.value = <int>[...history.value, count.value];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dartfier')),
      body: Center(
        child: Observer.withChild(
          childBuilder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('count: ${count.value}'),
              Text('doubled: ${doubled.value}'),
              Text('history: ${history.value}'),
              child!,
            ],
          ),
          child: const Text('static footer'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onIncrementTap,
        child: const Icon(Icons.add),
      ),
    );
  }
}
