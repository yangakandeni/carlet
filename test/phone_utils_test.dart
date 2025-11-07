import 'package:flutter_test/flutter_test.dart';
import 'package:carlet/utils/phone_utils.dart';

void main() {
  group('normalizePhone', () {
    test('accepts +27721457788', () {
      expect(normalizePhone('+27721457788'), '+27721457788');
    });

    test('accepts 0721457788 -> +27721457788', () {
      expect(normalizePhone('0721457788'), '+27721457788');
    });

    test('accepts 27721457788 -> +27721457788', () {
      expect(normalizePhone('27721457788'), '+27721457788');
    });

    test('accepts 721457788 -> +27721457788', () {
      expect(normalizePhone('721457788'), '+27721457788');
    });

    test('accepts 00 27 72 145 7788 -> +27721457788', () {
      expect(normalizePhone('00 27 72 145 7788'), '+27721457788');
    });

    test('returns null for short input', () {
      expect(normalizePhone('123'), isNull);
    });
  });
}
