import '../core/locale_controller.dart';

/// Сигнал остановки длительного сканирования.
class ScanCancellation {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

class ScanCancelledException implements Exception {
  @override
  String toString() => l10n.exceptionScanCancelled;
}
