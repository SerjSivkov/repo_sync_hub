import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sync_hub/core/concurrency.dart';

void main() {
  group('runWithConcurrency', () {
    test('results are returned in index order, not completion order',
        () async {
      // Чётные индексы «длинные», нечётные «короткие» — завершаются не по
      // порядку, но итоговый список должен идти 0..6.
      final results = await runWithConcurrency<int>(
        7,
        3,
        (i) async {
          await Future.delayed(Duration(milliseconds: i.isEven ? 40 : 5));
          return i;
        },
      );
      expect(results, [0, 1, 2, 3, 4, 5, 6]);
    });

    test('respects the concurrency limit', () async {
      var inflight = 0;
      var maxInflight = 0;
      await runWithConcurrency<void>(
        12,
        4,
        (i) async {
          inflight++;
          if (inflight > maxInflight) maxInflight = inflight;
          await Future.delayed(const Duration(milliseconds: 5));
          inflight--;
        },
      );
      expect(maxInflight, lessThanOrEqualTo(4));
      expect(maxInflight, greaterThan(1));
    });

    test('onResult receives every value with its index', () async {
      final seen = <int>[];
      await runWithConcurrency<int>(
        5,
        2,
        (i) async => i * 10,
        onResult: (i, value) {
          expect(value, i * 10);
          seen.add(i);
        },
      );
      expect(seen.toSet(), {0, 1, 2, 3, 4});
    });

    test('shouldStop halts dispatch of new tasks', () async {
      var started = 0;
      var stop = false;
      // Конкурентность 1 → строго последовательный запуск; после остановки
      // новых задач не должно быть. Уже начатая дорабатывает.
      await runWithConcurrency<void>(
        10,
        1,
        (i) async {
          started++;
          if (i == 2) stop = true;
          await Future.delayed(const Duration(milliseconds: 1));
        },
        shouldStop: () => stop,
      );
      expect(started, lessThanOrEqualTo(4));
      expect(started, greaterThanOrEqualTo(3));
    });

    test('empty count returns empty list', () async {
      final results = await runWithConcurrency<int>(0, 4, (i) async => i);
      expect(results, isEmpty);
    });

    test('clamps concurrency to count', () async {
      // count=2, concurrency=10 → реально 2 воркера, оба стартуют, не падаем.
      var inflight = 0;
      var maxInflight = 0;
      await runWithConcurrency<void>(
        2,
        10,
        (i) async {
          inflight++;
          if (inflight > maxInflight) maxInflight = inflight;
          await Future.delayed(const Duration(milliseconds: 5));
          inflight--;
        },
      );
      expect(maxInflight, lessThanOrEqualTo(2));
    });
  });
}
