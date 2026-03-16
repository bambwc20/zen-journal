import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_boilerplate/shared/utils/date_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppDateUtils', () {
    test('formatDate returns correct format', () {
      final date = DateTime(2026, 3, 16);
      expect(AppDateUtils.formatDate(date), '2026-03-16');
    });

    test('formatKoreanDate returns correct format', () {
      final date = DateTime(2026, 3, 16);
      expect(AppDateUtils.formatKoreanDate(date), '2026년 3월 16일');
    });

    test('isSameDay returns true for same day', () {
      final a = DateTime(2026, 3, 16, 10, 30);
      final b = DateTime(2026, 3, 16, 22, 0);
      expect(AppDateUtils.isSameDay(a, b), isTrue);
    });

    test('isSameDay returns false for different days', () {
      final a = DateTime(2026, 3, 16);
      final b = DateTime(2026, 3, 17);
      expect(AppDateUtils.isSameDay(a, b), isFalse);
    });

    test('getDaysInMonth returns correct count', () {
      expect(AppDateUtils.getDaysInMonth(2026, 3).length, 31);
      expect(AppDateUtils.getDaysInMonth(2026, 2).length, 28);
      expect(AppDateUtils.getDaysInMonth(2024, 2).length, 29);
    });

    test('formatRelative returns 방금 전 for recent time', () {
      final now = DateTime.now();
      expect(AppDateUtils.formatRelative(now), '방금 전');
    });
  });
}
