import 'package:flutter_test/flutter_test.dart';
import 'package:carlet/utils/plate_utils.dart';

void main() {
  group('isValidSouthAfricanPlate', () {
    test('validates new format plates with province codes', () {
      expect(isValidSouthAfricanPlate('CA 123-456'), true);
      expect(isValidSouthAfricanPlate('CA123456'), true);
      expect(isValidSouthAfricanPlate('ABC 123 GP'), true);
      expect(isValidSouthAfricanPlate('ABC123GP'), true);
      expect(isValidSouthAfricanPlate('CA 12-GP'), true);
      expect(isValidSouthAfricanPlate('CA12GP'), true);
    });

    test('validates old format plates', () {
      expect(isValidSouthAfricanPlate('TN 12345'), true);
      expect(isValidSouthAfricanPlate('TN12345'), true);
      expect(isValidSouthAfricanPlate('ABC 123'), true);
      expect(isValidSouthAfricanPlate('ABC123'), true);
      expect(isValidSouthAfricanPlate('T 123456'), true);
      expect(isValidSouthAfricanPlate('T123456'), true);
    });

    test('validates personalized/vanity plates', () {
      expect(isValidSouthAfricanPlate('CARLET'), true);
      expect(isValidSouthAfricanPlate('COOL1'), true);
      expect(isValidSouthAfricanPlate('ABC'), true);
      expect(isValidSouthAfricanPlate('COOL'), true);
      expect(isValidSouthAfricanPlate('BIKE123'), true);
    });

    test('accepts lowercase and mixed case plates', () {
      expect(isValidSouthAfricanPlate('ca 123-gp'), true);
      expect(isValidSouthAfricanPlate('Ca123Gp'), true);
      expect(isValidSouthAfricanPlate('carlet'), true);
    });

    test('rejects invalid plates', () {
      expect(isValidSouthAfricanPlate(''), false);
      expect(isValidSouthAfricanPlate('1'), false);
      expect(isValidSouthAfricanPlate('12345'), false);
      expect(isValidSouthAfricanPlate('ABCDEFGH'), false);
      expect(isValidSouthAfricanPlate('123456789'), false);
      expect(isValidSouthAfricanPlate('!@#\$%'), false);
      expect(isValidSouthAfricanPlate('AB'), false); // Too short
      expect(isValidSouthAfricanPlate('A1'), false); // Too short
    });

    test('handles plates with spaces and hyphens', () {
      expect(isValidSouthAfricanPlate('CA 123 GP'), true);
      expect(isValidSouthAfricanPlate('CA-123-GP'), true);
      expect(isValidSouthAfricanPlate('TN - 12345'), true);
    });
  });

  group('formatPlateForDisplay', () {
    test('formats new format plates correctly', () {
      expect(formatPlateForDisplay('ca123gp'), 'CA 123-GP');
      expect(formatPlateForDisplay('CA123GP'), 'CA 123-GP');
      expect(formatPlateForDisplay('abc456gp'), 'ABC 456-GP');
    });

    test('formats old format plates correctly', () {
      expect(formatPlateForDisplay('tn12345'), 'TN 12345');
      expect(formatPlateForDisplay('TN12345'), 'TN 12345');
      expect(formatPlateForDisplay('abc123'), 'ABC 123');
    });

    test('formats personalized plates correctly', () {
      expect(formatPlateForDisplay('carlet'), 'CARLET');
      expect(formatPlateForDisplay('cool1'), 'COOL1');
    });

    test('converts to uppercase', () {
      expect(formatPlateForDisplay('ca123gp'), contains('CA'));
      expect(formatPlateForDisplay('carlet'), equals('CARLET'));
    });

    test('removes extra spaces and hyphens', () {
      expect(formatPlateForDisplay('CA  123  GP'), 'CA 123-GP');
      expect(formatPlateForDisplay('CA---123---GP'), 'CA 123-GP');
    });
  });

  group('getPlateValidationError', () {
    test('returns user-friendly error message', () {
      final error = getPlateValidationError();
      expect(error, isNotEmpty);
      expect(error.toLowerCase(), contains('south african'));
    });
  });
}
