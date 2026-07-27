import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

void main() {
  group('ReadonlySignal', () {
    test('a Signal is assignable as ReadonlySignal', () {
      final Signal<int> count = Signal(1);
      final ReadonlySignal<int> view = count;

      expect(view.value, 1);
      expect(view.peek(), 1);
    });

    test('a Computed is assignable as ReadonlySignal', () {
      final Signal<int> count = Signal(2);
      final Computed<int> doubled = Computed(() => count.value * 2);
      final ReadonlySignal<int> view = doubled;

      expect(view.value, 4);
      expect(view.peek(), 4);
    });

    test('an AsyncSignal is assignable as ReadonlySignal of AsyncValue', () {
      final AsyncSignal<int> total = AsyncSignal();
      final ReadonlySignal<AsyncValue<int>> view = total;

      expect(view.value, const AsyncIdle<int>());
    });

    test('is assignable as ValueListenable', () {
      final ReadonlySignal<int> view = Signal(3);
      final ValueListenable<int> listenable = view;

      expect(listenable.value, 3);
    });

    test('tracks inside a Computed when read through the interface', () {
      final Signal<int> count = Signal(1);
      final ReadonlySignal<int> view = count;
      final Computed<int> doubled = Computed(() => view.value * 2);

      expect(doubled.value, 2);

      count.value = 3;

      expect(doubled.value, 6);
    });

    testWidgets('tracks inside an Observer when read through the interface', (
      tester,
    ) async {
      final Signal<int> count = Signal(0);
      final ReadonlySignal<int> view = count;

      await tester.pumpWidget(
        _host(Observer((context) => Text('${view.value}'))),
      );

      expect(find.text('0'), findsOneWidget);

      count.value = 1;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('works with ValueListenableBuilder', (tester) async {
      final Signal<int> count = Signal(0);
      final ReadonlySignal<int> view = count;

      await tester.pumpWidget(
        _host(
          ValueListenableBuilder<int>(
            valueListenable: view,
            builder: (_, value, _) => Text('$value'),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      count.value = 2;
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });
  });
}
