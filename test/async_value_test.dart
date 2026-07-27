import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsyncValue', () {
    test('AsyncIdle equality requires the exact generic type', () {
      expect(const AsyncIdle<int>(), const AsyncIdle<int>());
      expect(const AsyncIdle<int>().hashCode, const AsyncIdle<int>().hashCode);
      expect(const AsyncIdle<int>() == const AsyncIdle<num>(), isFalse);
      expect(const AsyncIdle<int>(), isNot(const AsyncLoading<int>()));
    });

    test('AsyncIdle carries no data and is not loading', () {
      expect(const AsyncIdle<int>().valueOrNull, isNull);
      expect(const AsyncIdle<int>().isLoading, isFalse);
    });

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

    test('equality requires the exact generic type', () {
      const AsyncData<num> wide = AsyncData<num>(1);
      const AsyncData<int> narrow = AsyncData<int>(1);

      expect(wide == narrow, isFalse);
      expect(narrow == wide, isFalse);
      expect(const AsyncData<int>(1), const AsyncData<int>(1));
      expect(
        const AsyncData<int>(1).hashCode,
        const AsyncData<int>(1).hashCode,
      );
    });

    test('AsyncData of a nullable type holding null still counts as data', () {
      const AsyncData<int?> data = AsyncData<int?>(null);

      expect(data.valueOrNull, isNull);
      expect(data.isLoading, isFalse);
      expect(data, isNot(const AsyncLoading<int?>()));
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

    test('toString names the state, the generic type and the payload', () {
      expect(const AsyncIdle<int>().toString(), 'AsyncIdle<int>()');
      expect(const AsyncLoading<int>().toString(), 'AsyncLoading<int>()');
      expect(
        const AsyncLoading<int>(previous: 1).toString(),
        'AsyncLoading<int>(previous: 1)',
      );
      expect(const AsyncData<int>(42).toString(), 'AsyncData<int>(42)');
      expect(const AsyncError<int>('boom').toString(), 'AsyncError<int>(boom)');
      expect(
        const AsyncError<int>('boom', previous: 1).toString(),
        'AsyncError<int>(boom, previous: 1)',
      );
    });
  });
}
