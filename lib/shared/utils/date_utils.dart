import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date, {String pattern = 'yyyy-MM-dd'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<DateTime> getDaysInMonth(int year, int month) {
    final last = DateTime(year, month + 1, 0);
    return List.generate(
      last.day,
      (i) => DateTime(year, month, i + 1),
    );
  }
}
