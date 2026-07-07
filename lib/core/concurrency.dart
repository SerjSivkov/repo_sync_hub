/// Запускает [action] для каждого индекса `0..count-1`, поддерживая не более
/// [concurrency] одновременных задач (паттерн worker-pool).
///
/// Результаты возвращаются **в порядке индексов**, а не завершения — итоговый
/// список детерминирован. [onResult] вызывается по завершении каждой задачи
/// (удобно для счётчиков/прогресса). [shouldStop], если задан, проверяется
/// перед выдачей нового индекса: при `true` новые задачи не стартуют, уже
/// запущенные дорабатывают до конца.
///
/// Безопасен в однопоточном isolate Dart: `next++` между `await` атомарна,
/// гонок на общей позиции нет.
Future<List<R?>> runWithConcurrency<R>(
  int count,
  int concurrency,
  Future<R> Function(int index) action, {
  void Function(int index, R value)? onResult,
  bool Function()? shouldStop,
}) async {
  final results = List<R?>.filled(count, null);
  if (count <= 0) return results;

  final workers = concurrency.clamp(1, count);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      if (shouldStop != null && shouldStop()) return;
      final i = next;
      if (i >= count) return;
      next += 1;
      final value = await action(i);
      results[i] = value;
      onResult?.call(i, value);
    }
  }

  await Future.wait([
    for (var w = 0; w < workers; w++) worker(),
  ]);
  return results;
}
