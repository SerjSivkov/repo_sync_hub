/// Форматирование размеров, дат и чисел для UI.
class Format {
  Format._();

  static String bytes(int? value) {
    if (value == null) return '—';
    if (value < 1024) return '$value Б';
    const units = ['КБ', 'МБ', 'ГБ', 'ТБ'];
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
  static String relativeDate(DateTime? date) {
    if (date == null) return 'никогда';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) return dateTime(date);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} нед назад';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} мес назад';
    final years = (diff.inDays / 365).floor();
    return '$years ${years == 1 ? 'год' : 'г'} назад';
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
