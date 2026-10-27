// Display formatting helpers.

class Formatters {
  Formatters._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "just now", "5 min ago", "3 h ago", "2 d ago", else "12 Oct 2026".
  static String timeAgo(DateTime? time, {DateTime? now}) {
    if (time == null) return 'just now';
    final current = now ?? DateTime.now();
    final diff = current.difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return date(time);
  }

  static String date(DateTime? time) {
    if (time == null) return '';
    return '${time.day} ${_months[time.month - 1]} ${time.year}';
  }

  /// "+94 77 123 4567" from "+94771234567".
  static String phone(String? e164) {
    if (e164 == null || e164.isEmpty) return '';
    final m = RegExp(r'^\+94(\d{2})(\d{3})(\d{4})$').firstMatch(e164);
    if (m == null) return e164;
    return '+94 ${m.group(1)} ${m.group(2)} ${m.group(3)}';
  }

  static String rating(double value) => value.toStringAsFixed(1);
}
