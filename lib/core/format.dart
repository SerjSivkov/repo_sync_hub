import '../l10n/app_localizations.dart';

/// Форматирование размеров, дат и чисел для UI. Локализуется через [AppLocalizations].
class Format {
  Format._();

  static String bytes(AppLocalizations l10n, int? value) {
    if (value == null) return '—';
    if (value < 1024) return '$value ${l10n.unitB}';
    final units = [l10n.unitKB, l10n.unitMB, l10n.unitGB, l10n.unitTB];
    double size = value / 1024;
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(digits)} ${units[unit]}';
  }

  static String count(int? value) {
    if (value == null) return '—';
    if (value < 1000) return '$value';
    if (value < 1000000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Относительная дата: «только что», «5 мин назад», «3 дня назад», дата.
  static String relativeDate(AppLocalizations l10n, DateTime? date) {
    if (date == null) return l10n.fmtNever;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) return dateTime(date);
    if (diff.inMinutes < 1) return l10n.fmtJustNow;
    if (diff.inMinutes < 60) return l10n.fmtMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.fmtHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.fmtDaysAgo(diff.inDays);
    if (diff.inDays < 30) return l10n.fmtWeeksAgo((diff.inDays / 7).floor());
    if (diff.inDays < 365) return l10n.fmtMonthsAgo((diff.inDays / 30).floor());
    return l10n.fmtYearsAgo((diff.inDays / 365).floor());
  }

  static String date(DateTime? d) {
    if (d == null) return '—';
    return '${_two(d.day)}.${_two(d.month)}.${d.year}';
  }

  static String dateTime(DateTime? d) {
    if (d == null) return '—';
    return '${date(d)} ${_two(d.hour)}:${_two(d.minute)}';
  }
}
