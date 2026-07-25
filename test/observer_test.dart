import 'package:dartfier/dartfier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

class _ProbeSignal<T> extends Signal<T> {
  _ProbeSignal(super.initial);

  bool get isObserved => hasListeners;
}

void main() {
  group('Observer', () {
    testWidgets('rebuilds when a signal read in the builder changes', (
      tester,
    ) async {
      final Signal<int> count = Signal(0);

      await tester.pumpWidget(
        _host(Observer((context) => Text('${count.value}'))),
      );

      expect(find.text('0'), findsOneWidget);

      count.value = 1;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('does not rebuild when an unread signal changes', (
      tester,
    ) async {
      final Signal<int> read = Signal(0);
      final Signal<int> unread = Signal(0);
      int builds = 0;

      await tester.pumpWidget(
        _host(
          Observer((context) {
            builds++;

            return Text('${read.value}');
          }),
        ),
      );

      unread.value = 5;
      await tester.pump();

      expect(builds, 1);
    });

    testWidgets('passes the build context to the builder', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Observer((context) => Text(Directionality.of(context).name)),
        ),
      );

      expect(find.text('rtl'), findsOneWidget);
    });

    testWidgets('rebuilds when a computed result changes', (tester) async {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);

      await tester.pumpWidget(
        _host(Observer((context) => Text('${doubled.value}'))),
      );

      expect(find.text('2'), findsOneWidget);

      count.value = 4;
      await tester.pump();

      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('retracks conditional reads across rebuilds', (tester) async {
      final Signal<bool> flag = Signal(true);
      final Signal<int> a = Signal(1);
      final Signal<int> b = Signal(2);
      int builds = 0;

      await tester.pumpWidget(
        _host(
          Observer((context) {
            builds++;

            return Text('${flag.value ? a.value : b.value}');
          }),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      flag.value = false;
      await tester.pump();

      expect(find.text('2'), findsOneWidget);

      a.value = 99;
      await tester.pump();

      expect(builds, 2);
    });

    testWidgets('unsubscribes from signals when removed from the tree', (
      tester,
    ) async {
      final _ProbeSignal<int> count = _ProbeSignal(0);

      await tester.pumpWidget(
        _host(Observer((context) => Text('${count.value}'))),
      );

      expect(count.isObserved, isTrue);

      await tester.pumpWidget(_host(const SizedBox()));

      expect(count.isObserved, isFalse);

      count.value = 1;
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not track reads inside a nested builder', (tester) async {
      final Signal<int> count = Signal(0);
      int outerBuilds = 0;

      await tester.pumpWidget(
        _host(
          Observer((context) {
            outerBuilds++;

            return Builder(builder: (context) => Text('${count.value}'));
          }),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      count.value = 1;
      await tester.pump();

      expect(outerBuilds, 1);
      expect(find.text('0'), findsOneWidget);
    });
  });
}
