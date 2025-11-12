import 'package:flutter_test/flutter_test.dart';
import 'package:carlet/utils/phone_utils.dart';

void main() {
  group('isValidSouthAfricanPhone', () {
    test('validates mobile numbers starting with 6', () {
      expect(isValidSouthAfricanPhone('+27601234567'), true);
      expect(isValidSouthAfricanPhone('0601234567'), true);
      expect(isValidSouthAfricanPhone('27601234567'), true);
      expect(isValidSouthAfricanPhone('601234567'), true);
    });

    test('validates mobile numbers starting with 7', () {
      expect(isValidSouthAfricanPhone('+27721457788'), true);
      expect(isValidSouthAfricanPhone('0721457788'), true);
      expect(isValidSouthAfricanPhone('27721457788'), true);
      expect(isValidSouthAfricanPhone('721457788'), true);
    });

    test('validates mobile numbers starting with 8', () {
      expect(isValidSouthAfricanPhone('+27801234567'), true);
      expect(isValidSouthAfricanPhone('0801234567'), true);
      expect(isValidSouthAfricanPhone('27801234567'), true);
      expect(isValidSouthAfricanPhone('801234567'), true);
    });

    test('validates landline numbers starting with 1', () {
      expect(isValidSouthAfricanPhone('+27101234567'), true);
      expect(isValidSouthAfricanPhone('0101234567'), true);
    });

    test('validates landline numbers starting with 2', () {
      expect(isValidSouthAfricanPhone('+27212345678'), true);
      expect(isValidSouthAfricanPhone('0212345678'), true);
    });

    test('validates landline numbers starting with 3', () {
      expect(isValidSouthAfricanPhone('+27312345678'), true);
      expect(isValidSouthAfricanPhone('0312345678'), true);
    });

    test('validates landline numbers starting with 4', () {
      expect(isValidSouthAfricanPhone('+27412345678'), true);
      expect(isValidSouthAfricanPhone('0412345678'), true);
    });

    test('validates landline numbers starting with 5', () {
      expect(isValidSouthAfricanPhone('+27512345678'), true);
      expect(isValidSouthAfricanPhone('0512345678'), true);
    });

    test('accepts numbers with spaces and hyphens', () {
      expect(isValidSouthAfricanPhone('072 145 7788'), true);
      expect(isValidSouthAfricanPhone('072-145-7788'), true);
      expect(isValidSouthAfricanPhone('+27 72 145 7788'), true);
      expect(isValidSouthAfricanPhone('00 27 72 145 7788'), true);
    });

    test('rejects invalid prefixes', () {
      expect(isValidSouthAfricanPhone('+27091234567'), false); // 0 not valid as first digit
      expect(isValidSouthAfricanPhone('+27991234567'), false); // 9 not valid as first digit
      expect(isValidSouthAfricanPhone('0091234567'), false);
    });

    test('rejects numbers that are too short', () {
      expect(isValidSouthAfricanPhone('+2772145778'), false); // 8 digits
      expect(isValidSouthAfricanPhone('072145778'), false);
      expect(isValidSouthAfricanPhone('+27721'), false);
    });

    test('rejects numbers that are too long', () {
      expect(isValidSouthAfricanPhone('+277214577889'), false); // 10 digits
      expect(isValidSouthAfricanPhone('07214577889'), false);
    });

    test('rejects non-SA country codes', () {
      expect(isValidSouthAfricanPhone('+1234567890'), false); // US
      expect(isValidSouthAfricanPhone('+447911123456'), false); // UK
      expect(isValidSouthAfricanPhone('+917911123456'), false); // India
    });

    test('rejects empty or invalid input', () {
      expect(isValidSouthAfricanPhone(''), false);
      expect(isValidSouthAfricanPhone('abc'), false);
      expect(isValidSouthAfricanPhone('!@#\$%'), false);
    });
  });

  group('getPhoneValidationError', () {
    test('returns user-friendly error message', () {
      final error = getPhoneValidationError();
      expect(error, isNotEmpty);
      expect(error.toLowerCase(), contains('south african'));
    });
  });

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
