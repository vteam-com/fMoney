import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/currency_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/account_widgets_helper.dart';
import 'package:money/widgets/list/list_item_card.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  /// Creates an account in [currency], whose exchange ratio to the default currency is [ratio].
  Account accountIn(String currency, double ratio) {
    Data().currencies.appendNewMoneyObject(
      Currency(id: -1, symbol: currency, name: currency, ratio: ratio, cultureCode: '', lastRatio: ratio),
      fireNotification: false,
    );
    return createTestAccount('Account $currency')..fieldCurrency.value = currency;
  }

  setUp(resetTestData);

  tearDown(() => Data().clearExistingData());

  test('amounts convert to the default currency with the account ratio, or stay as is without one', () {
    final Account canadian = accountIn('CAD', 0.75);
    final Account unknownRate = accountIn('XYZ', 0);

    expect(canadian.toNormalized(100), 75);
    expect(unknownRate.toNormalized(100), 100);

    unknownRate.balance = 100;
    expect((unknownRate.fieldBalanceNormalized.getValueForDisplay(unknownRate) as AmountModel).asDouble(), 100);

    final Transaction transaction = createTestTransaction(canadian, 'Store');
    expect(transaction.getNormalizedAmount(100), 75);
  });

  test('the small-screen card shows the default currency on top and the native balance below', () {
    final Account canadian = accountIn('CAD', 0.75)..balance = 100;

    final MyListItemAsCard card = buildAccountSmallScreenWidget(canadian) as MyListItemAsCard;
    final Tooltip tooltip = card.rightBottomAsWidget! as Tooltip;
    final Text nativeBalance = (tooltip.child! as Row).children.first as Text;

    expect(card.rightTopAsString, getAmountAsStringUsingCurrency(75));
    expect(nativeBalance.data, getAmountAsStringUsingCurrency(100, iso4217code: 'CAD'));
  });
}
