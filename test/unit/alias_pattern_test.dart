import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/alias_pattern_optimizer_helper.dart';
import 'package:money/shared/domain/alias_pattern_parser_helper.dart';
import 'package:money/shared/domain/alias_pattern_suggestion_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/presentation/entity_widgets/alias_pattern_explanation_helper.dart';

import '../helpers/test_fixtures_helper.dart';

/// An alias of [type] with [pattern], not added to the data.
Alias _alias(String pattern, {AliasType type = AliasType.regex, int payeeId = -1}) =>
    Alias(id: -1, pattern: pattern, flags: type.index, payeeId: payeeId, data: Data());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetTestData);

  group('optimizedAliasPattern', () {
    /// Expects [texts] to give [expected], a pattern that matches each of them.
    void expectPattern(List<String> texts, String expected, {List<String> mustNotMatch = const <String>[]}) {
      final String pattern = optimizedAliasPattern(texts, mustNotMatch: mustNotMatch);
      expect(pattern, expected);
      for (final String text in texts) {
        expect(_alias(pattern).isMatch(text), isTrue, reason: '$pattern must match $text');
      }
    }

    test('keeps a single text as it is', () {
      expectPattern(<String>['AMAZON.COM*AB12'], r'(?i)AMAZON\.COM\*AB12');
      expectPattern(<String>['Netflix', 'NETFLIX'], '(?i)Netflix');
      expect(optimizedAliasPattern(<String>['', ' ']), '');
    });

    test('replaces what differs with any text, or with a number', () {
      expectPattern(<String>['AMAZON.COM*AB12CD', 'AMAZON.COM*XY99ZZ'], r'(?i)AMAZON\.COM\*.*');
      expectPattern(<String>[
        'SQ *BLUE BOTTLE 0123 OAKLAND CA',
        'SQ *BLUE BOTTLE 9876 OAKLAND CA',
      ], r'(?i)SQ \*BLUE BOTTLE \d+ OAKLAND CA');
      expectPattern(<String>['STORE 1234', 'STORE 1299'], r'(?i)STORE \d+');
    });

    test('keeps merchants that start differently apart', () {
      expectPattern(<String>['AMAZON MKTP', 'AMAZON.COM', 'AMZN Mktp US'], '(?i)(?:AMZN Mktp US|AMAZON.*)');
      expectPattern(<String>['SQ *BLUE BOTTLE', 'SQ *COFFEE'], r'(?i)(?:SQ \*BLUE BOTTLE|SQ \*COFFEE)');
      expectPattern(<String>['SQ *BLUE BOTTLE', 'SQ *BLUEMOON CAFE'], r'(?i)SQ \*BLUE.*');
    });

    test('lists the texts when a shorter pattern would match a text it must not', () {
      expectPattern(<String>['ATT*BILL', 'ATT WIRELESS'], '(?i)ATT.*');
      expectPattern(
        <String>['ATT*BILL', 'ATT WIRELESS'],
        r'(?i)(?:ATT WIRELESS|ATT\*BILL)',
        mustNotMatch: <String>['ATT UVERSE'],
      );
    });

    test('puts a text before the shorter texts it starts with, so both match', () {
      expectPattern(<String>['AB', 'ABC'], '(?i)(?:ABC|AB)');
    });
  });

  group('parseAliasPattern', () {
    test('returns the texts of a pattern that only lists texts', () {
      expect(literalTextsOf(parseAliasPattern(r'(?i)(?:ATT\*BILL|ATT WIRELESS)')!.parts), <String>[
        'ATT*BILL',
        'ATT WIRELESS',
      ]);
      expect(literalTextsOf(parseAliasPattern(r'NETFLIX\.COM')!.parts), <String>['NETFLIX.COM']);
      expect(literalTextsOf(parseAliasPattern('(?i)AMAZON.*')!.parts), isNull);
      expect(parseAliasPattern('('), isNull);
    });
  });

  group('explainAliasPattern', () {
    /// The explanation of [alias], one line per entry, indented two spaces per level.
    List<String> explain(Alias alias) => explainAliasPattern(
      alias,
    ).map((AliasExplanationLine line) => '${'  ' * line.depth}${line.text}').toList();

    test('reads a generalized pattern part by part', () {
      expect(explain(_alias(r'(?i)SQ \*BLUE BOTTLE \d+ OAKLAND CA')), <String>[
        'Upper and lower case are treated the same',
        'The text “SQ *BLUE BOTTLE ”',
        'A number (one or more digits)',
        'The text “ OAKLAND CA”',
        'It must match the whole bank text or payee name',
      ]);
    });

    test('lists each choice under its number', () {
      expect(explain(_alias('(?i)(?:AMZN Mktp US|AMAZON.*)')), <String>[
        'Upper and lower case are treated the same',
        'One of these 2 choices',
        '  Choice 1',
        '    The text “AMZN Mktp US”',
        '  Choice 2',
        '    The text “AMAZON”',
        '    Any text, or nothing',
        'It must match the whole bank text or payee name',
      ]);
    });

    test('says how many times a part repeats', () {
      expect(explain(_alias(r'AB?[0-9]{2,4}x{3}(?:ab)+\s*.+[^,]')), <String>[
        'Upper and lower case must match',
        'The text “A”',
        'The text “B”, optional',
        'One of the characters “0-9”, 2 to 4 times',
        'The text “x”, 3 times',
        'This group, one or more times',
        '  The text “ab”',
        'A space, any number of times, or none',
        'Any text',
        'One character other than “,”',
        'It must match the whole bank text or payee name',
      ]);
    });

    test('explains a plain pattern and an invalid regex', () {
      expect(explain(_alias('NETFLIX', type: AliasType.none)), <String>[
        'Matches a bank text or payee name equal to “NETFLIX”, ignoring case',
      ]);
      expect(explain(_alias('AMAZON(')), <String>['This is not a valid regular expression']);
      expect(explain(_alias('')), isEmpty);
    });
  });

  group('suggestAliasPattern', () {
    late Account checking;
    late Payee amazon;

    setUp(() {
      checking = createTestAccount();
      amazon = Data().payees.getOrCreate('Amazon', fireNotification: false);
      for (final String text in <String>['AMAZON.COM*AB12', 'AMAZON.COM*CD34', 'AMAZON.COM*EF56']) {
        createTestTransaction(checking, 'Amazon', originalPayee: text);
      }
    });

    test("covers the bank texts of the alias's payee", () {
      final AliasPatternSuggestion suggestion = Data().suggestAliasPattern(
        _alias('AMAZON.COM*AB12', type: AliasType.none, payeeId: amazon.uniqueId),
      );
      expect(suggestion, (currentMatches: 1, pattern: r'(?i)AMAZON\.COM\*.*', matches: 3));
    });

    test('shortens a pattern that lists texts', () {
      final Alias alias = _alias(
        r'(?i)(?:AMAZON\.COM\*AB12|AMAZON\.COM\*CD34|AMAZON\.COM\*EF56)',
        payeeId: amazon.uniqueId,
      );
      expect(Data().suggestAliasPattern(alias), (currentMatches: 3, pattern: r'(?i)AMAZON\.COM\*.*', matches: 3));
    });

    test("never reaches another payee's transactions", () {
      createTestTransaction(checking, 'Amazon Prime', originalPayee: 'AMAZON.COM*PRIME');
      final AliasPatternSuggestion suggestion = Data().suggestAliasPattern(
        _alias('AMAZON.COM*AB12', type: AliasType.none, payeeId: amazon.uniqueId),
      );
      expect(suggestion.matches, 3);
      expect(_alias(suggestion.pattern!).isMatch('AMAZON.COM*PRIME'), isFalse);
    });

    test('has nothing better for an alias that already covers them', () {
      final Alias alias = _alias(r'(?i)AMAZON\.COM\*.*', payeeId: amazon.uniqueId);
      expect(Data().suggestAliasPattern(alias), (currentMatches: 3, pattern: null, matches: 3));
    });
  });
}
