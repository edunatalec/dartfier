import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Signal', () {
    test('holds the initial value', () {
      final Signal<int> count = Signal(0);

      expect(count.value, 0);
    });

    test('notifies listeners when the value changes', () {
      final Signal<int> count = Signal(0);
      int notifications = 0;
      count.addListener(() => notifications++);

      count.value = 1;

      expect(count.value, 1);
      expect(notifications, 1);
    });

    test('does not notify when the new value is equal', () {
      final Signal<int> count = Signal(0);
      int notifications = 0;
      count.addListener(() => notifications++);

      count.value = 0;

      expect(notifications, 0);
    });

    test('ignores writes after dispose', () {
      final Signal<int> count = Signal(0);
      count.dispose();

      count.value = 1;

      expect(count.value, 0);
    });

    test('implements ValueListenable for interop', () {
      final Signal<int> count = Signal(7);

      expect(count, isA<ValueListenable<int>>());
    });
  });
}
