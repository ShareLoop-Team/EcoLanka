// QA (Umayanga): validation & anti-resell rules.
import 'package:ecolanka/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Anti-resell detection', () {
    test('flags prices and sale wording', () {
      expect(Validators.looksLikeSale('Rs. 500 only'), isTrue);
      expect(Validators.looksLikeSale('rs500'), isTrue);
      expect(Validators.looksLikeSale('Price negotiable'), isTrue);
      expect(Validators.looksLikeSale('For sale: old chair'), isTrue);
      expect(Validators.looksLikeSale('Selling my books'), isTrue);
      expect(Validators.looksLikeSale('2000 LKR'), isTrue);
    });

    test('allows normal donation text', () {
      expect(Validators.looksLikeSale('Grade 10 science textbooks'), isFalse);
      expect(Validators.looksLikeSale('Free school shoes, size 5'), isFalse);
      expect(Validators.looksLikeSale('Gently used kids clothes'), isFalse);
    });
  });

  group('Item title', () {
    test('rejects too short / too long / sale wording', () {
      expect(Validators.itemTitle('ab'), isNotNull);
      expect(Validators.itemTitle('a' * 81), isNotNull);
      expect(Validators.itemTitle('Chair for sale'), isNotNull);
    });
    test('accepts a valid title', () {
      expect(Validators.itemTitle('Wooden study table'), isNull);
    });
  });

  group('Item description', () {
    test('required and max 1000', () {
      expect(Validators.itemDescription(''), isNotNull);
      expect(Validators.itemDescription('x' * 1001), isNotNull);
      expect(Validators.itemDescription('Good condition, pick up in Kandy'), isNull);
    });
  });

  group('Request message', () {
    test('5–500 characters', () {
      expect(Validators.requestMessage('hi'), isNotNull);
      expect(Validators.requestMessage('I need this for my daughter'), isNull);
      expect(Validators.requestMessage('x' * 501), isNotNull);
    });
  });

  group('Sri Lankan mobile numbers', () {
    test('valid operator prefixes', () {
      expect(Validators.isSriLankanMobile('771234567'), isTrue);
      expect(Validators.isSriLankanMobile('701234567'), isTrue);
      expect(Validators.isSriLankanMobile('781234567'), isTrue);
    });
    test('invalid numbers', () {
      expect(Validators.isSriLankanMobile('731234567'), isFalse); // no 73 prefix
      expect(Validators.isSriLankanMobile('77123456'), isFalse); // too short
      expect(Validators.isSriLankanMobile('0771234567'), isFalse); // leading 0
    });
  });

  group('Display name', () {
    test('2–50 characters', () {
      expect(Validators.displayName('A'), isNotNull);
      expect(Validators.displayName('Dulum'), isNull);
      expect(Validators.displayName('x' * 51), isNotNull);
    });
  });
}
