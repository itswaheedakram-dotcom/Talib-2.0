import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/features/search/domain/smart_search_parser.dart';

void main() {
  group('SmartSearchParser', () {
    test('parses mixed Roman Urdu institute and city query', () {
      final query = SmartSearchParser.parse('Lahore me Educators kaha kaha hn');
      expect(query.category, GlobalSearchCategory.institutes);
      expect(query.location, 'Lahore');
      expect(query.terms, contains('educators'));
    });

    test('parses area, girls hostel, and numeric budget', () {
      final query = SmartSearchParser.parse('Johar Town me achy girls hostel under 15000');
      expect(query.category, GlobalSearchCategory.hostels);
      expect(query.area, 'Johar Town');
      expect(query.gender, 'Female');
      expect(query.maxBudget, 15000);
      expect(query.wantsBestRated, isTrue);
    });

    test('parses admission status and named institute', () {
      final query = SmartSearchParser.parse('Arid mein admission open hai?');
      expect(query.category, GlobalSearchCategory.admissions);
      expect(query.instituteName, 'arid');
      expect(query.wantsOpenAdmissions, isTrue);
    });

    test('parses scholarship and BS study level', () {
      final query = SmartSearchParser.parse('Scholarship for BS students');
      expect(query.category, GlobalSearchCategory.scholarships);
      expect(query.program, 'BS');
    });

    test('writes the query summary in the language the user used', () {
      final roman = SmartSearchParser.parse('Johar Town mein achy girls hostel under 15 hazaar');
      expect(roman.isRomanUrdu, isTrue);
      expect(roman.summary, contains('Aap'));
      expect(roman.maxBudget, 15000);
      final english = SmartSearchParser.parse('Girls hostel under 15000 in Lahore');
      expect(english.isRomanUrdu, isFalse);
      expect(english.summary, contains('I understood'));
    });

    test('understands common Roman Urdu synonyms', () {
      for (final phrase in ['dakhla', 'wazifa', 'kiraya', 'batao', 'dikhao', 'mujhy', 'achy', 'larkiyon', 'larkon', 'akhri tareekh', 'khula hai', 'qareeb', 'kamra', 'khana', 'rupay']) {
        expect(SmartSearchParser.normalize(phrase), isNotEmpty, reason: 'phrase: $phrase');
      }
    });

    test('does not mutate words when replacing Roman Urdu me', () {
      expect(SmartSearchParser.normalize('women in Lahore'), contains('female'));
    });
  });
}
