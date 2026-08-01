import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

Widget _counterView(ValueListenable<int> listenable) {
  return _host(
    ValueListenableBuilder<int>(
      valueListenable: listenable,
      builder: (_, int value, _) => Text('count: $value'),
    ),
  );
}

void main() {
  group('ValueListenable interop', () {
    testWidgets('a Computed drives a ValueListenableBuilder', (tester) async {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);

      await tester.pumpWidget(_counterView(doubled));

      expect(find.text('count: 2'), findsOneWidget);

      count.value = 5;
      await tester.pump();

      expect(find.text('count: 10'), findsOneWidget);
    });

    testWidgets('a merged Signal and Computed drive a ListenableBuilder', (
      tester,
    ) async {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);

      await tester.pumpWidget(
        _host(
          ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[count, doubled]),
            builder: (_, _) => Text('${count.peek()} / ${doubled.peek()}'),
          ),
        ),
      );

      expect(find.text('1 / 2'), findsOneWidget);

      count.value = 4;
      await tester.pump();

      expect(find.text('4 / 8'), findsOneWidget);
    });

    testWidgets('a Signal replaces a ValueNotifier without touching the '
        'consumer', (tester) async {
      final ValueNotifier<int> notifier = ValueNotifier<int>(0);

      await tester.pumpWidget(_counterView(notifier));

      expect(find.text('count: 0'), findsOneWidget);

      notifier.value = 3;
      await tester.pump();

      expect(find.text('count: 3'), findsOneWidget);

      final Signal<int> signal = Signal(0);

      await tester.pumpWidget(_counterView(signal));

      expect(find.text('count: 0'), findsOneWidget);

      signal.value = 3;
      await tester.pump();

      expect(find.text('count: 3'), findsOneWidget);
    });

    test('addListener and removeListener behave like a ChangeNotifier', () {
      final Signal<int> count = Signal(0);

      int notifications = 0;
      void listener() => notifications++;

      count.addListener(listener);
      count.value = 1;

      expect(notifications, 1);

      count.removeListener(listener);
      count.value = 2;

      expect(notifications, 1);
    });

    test('a write after dispose notifies nobody', () {
      final Signal<int> count = Signal(0);

      int notifications = 0;
      count.addListener(() => notifications++);

      count.dispose();
      count.value = 1;

      expect(notifications, 0);
      expect(count.value, 0);
    });
  });
}
