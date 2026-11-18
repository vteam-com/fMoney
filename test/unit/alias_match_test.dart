import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Builds a detached alias of [type] for [pattern].
Alias _alias(String pattern, AliasType type) =>
    Alias(id: -1, pattern: pattern, flags: type.index, payeeId: -1, data: null);

void main() {
  group('regex alias', () {
    test('must cover the whole payee name, like MyMoney.Net', () {
      final Alias att = _alias('ATT', AliasType.regex);
      expect(att.isMatch('ATT'), isTrue);
      expect(att.isMatch('MATTRESS FIRM'), isFalse);
      expect(att.isMatch('ATT*BILL PAYMENT'), isFalse);

      expect(_alias('.*ALASKA[ ]+AIR.*', AliasType.regex).isMatch('SQ ALASKA  AIRLINES 0271'), isTrue);
    });

    test('is case-sensitive unless the pattern starts with (?i)', () {
      expect(_alias('ATT.*', AliasType.regex).isMatch('att*bill payment'), isFalse);
      expect(_alias('(?i)ATT.*', AliasType.regex).isMatch('att*bill payment'), isTrue);
    });

    test('an invalid pattern does not throw and does not match', () {
      expect(_alias('[ATT', AliasType.regex).isMatch('[ATT'), isFalse);
      expect(_alias('(?x)ATT', AliasType.regex).isMatch('ATT'), isFalse);
    });

    test('an edited pattern is recompiled', () {
      final Alias alias = _alias('ATT', AliasType.regex);
      expect(alias.isMatch('AT&T'), isFalse);
      alias.fieldPattern.value = 'AT&?T';
      expect(alias.isMatch('AT&T'), isTrue);
    });
  });

  test('plain alias equals the payee name ignoring case', () {
    final Alias alias = _alias('Starbucks', AliasType.none);
    expect(alias.isMatch('STARBUCKS'), isTrue);
    expect(alias.isMatch('STARBUCKS #12'), isFalse);
  });

  test('a blank payee name never matches', () {
    expect(_alias('.*', AliasType.regex).isMatch(' '), isFalse);
    expect(_alias('', AliasType.none).isMatch(''), isFalse);
  });

  test('an invalid alias does not stop the lookup on import', () {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    final Payee att = Data().payees.getOrCreate('AT&T');
    Data().aliases.appendNewMoneyObject(
      Alias(id: -1, pattern: '(?x)broken', flags: AliasType.regex.index, payeeId: att.uniqueId, data: Data()),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(id: -1, pattern: '(?i)ATT.*', flags: AliasType.regex.index, payeeId: att.uniqueId, data: Data()),
      fireNotification: false,
    );

    expect(Data().aliases.findByMatch('att* wireless'), same(att));
  });
}
