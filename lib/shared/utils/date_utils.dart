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

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}개월 전';
    return '${diff.inDays ~/ 365}년 전';
  }

  static String formatKoreanDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
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
