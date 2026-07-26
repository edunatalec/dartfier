import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsyncValue', () {
    test('AsyncData equality compares the value', () {
      expect(const AsyncData<int>(1), const AsyncData<int>(1));
      expect(const AsyncData<int>(1), isNot(const AsyncData<int>(2)));
    });

    test('AsyncLoading equality includes previous', () {
      expect(const AsyncLoading<int>(), const AsyncLoading<int>());
      expect(
        const AsyncLoading<int>(previous: 1),
        const AsyncLoading<int>(previous: 1),
      );
      expect(
        const AsyncLoading<int>(previous: 1),
        isNot(const AsyncLoading<int>()),
      );
    });

    test('AsyncError equality ignores the stack trace', () {
      final AsyncError<int> a = AsyncError<int>(
        'boom',
        stackTrace: StackTrace.current,
        previous: 1,
      );
      final AsyncError<int> b = AsyncError<int>(
        'boom',
        stackTrace: StackTrace.current,
        previous: 1,
      );

      expect(a, b);
      expect(a, isNot(const AsyncError<int>('boom', previous: 2)));
    });

    test('valueOrNull returns data, previous or null', () {
      expect(const AsyncData<int>(3).valueOrNull, 3);
      expect(const AsyncLoading<int>(previous: 2).valueOrNull, 2);
      expect(const AsyncError<int>('boom', previous: 1).valueOrNull, 1);
      expect(const AsyncLoading<int>().valueOrNull, isNull);
    });

    test('isLoading is true only while loading', () {
      expect(const AsyncLoading<int>().isLoading, isTrue);
      expect(const AsyncData<int>(1).isLoading, isFalse);
      expect(const AsyncError<int>('boom').isLoading, isFalse);
    });
  });
}
