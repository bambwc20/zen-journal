import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_boilerplate/shared/utils/string_utils.dart';

void main() {
  group('StringUtils', () {
    test('truncate shortens long text', () {
      expect(StringUtils.truncate('Hello World', 8), 'Hello...');
    });

    test('truncate returns original if short enough', () {
      expect(StringUtils.truncate('Hi', 8), 'Hi');
    });

    test('capitalize makes first letter uppercase', () {
      expect(StringUtils.capitalize('hello'), 'Hello');
    });

    test('capitalize handles empty string', () {
      expect(StringUtils.capitalize(''), '');
    });

    test('isNullOrEmpty returns true for null', () {
      expect(StringUtils.isNullOrEmpty(null), isTrue);
    });

    test('isNullOrEmpty returns true for empty', () {
      expect(StringUtils.isNullOrEmpty(''), isTrue);
    });

    test('isNullOrEmpty returns true for whitespace', () {
      expect(StringUtils.isNullOrEmpty('  '), isTrue);
    });

    test('isNullOrEmpty returns false for non-empty', () {
      expect(StringUtils.isNullOrEmpty('hello'), isFalse);
    });

    test('formatNumber formats thousands', () {
      expect(StringUtils.formatNumber(1500), '1.5K');
    });

    test('formatNumber formats millions', () {
      expect(StringUtils.formatNumber(2500000), '2.5M');
    });

    test('formatNumber returns raw for small numbers', () {
      expect(StringUtils.formatNumber(42), '42');
    });
  });
}
