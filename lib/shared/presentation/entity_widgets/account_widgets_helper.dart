import 'package:money/data/models/account_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/picker_account_type.dart';
import 'package:money/widgets/pickers/token_text_widget.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// Returns the [Account]-specific display widget for [field], or null for the generic one.
Widget? buildAccountFieldDisplayWidget(Account account, Field<dynamic> field) {
  if (field.isSameDefinition(account.fieldCurrency)) {
    return buildAccountCurrencyWidget(account);
  }
  if (field.isSameDefinition(account.fieldName)) {
    return TokenText(account.fieldName.value);
  }
  return null;
}

/// Returns the [Account]-specific editor for [field], or null for the generic one.
Widget? buildAccountFieldEditWidget(
  Account account,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  if (field.isSameDefinition(account.fieldType)) {
    return pickerAccountType(
      itemSelected: account.fieldType.value,
      onSelected: (AccountType newSelection) {
        account.fieldType.value = newSelection;
        onEdited(true); // notify container
      },
    );
  }
  return null;
}

/// Builds the small-screen card for [account].
Widget buildAccountSmallScreenWidget(Account account) {
  Widget? originalCurrencyAndValue;

  if (account.fieldCurrency.value == Constants.defaultCurrency) {
    originalCurrencyAndValue = buildCurrencyWidget(
      account.fieldCurrency.value,
    );
  } else {
    final double ratioCurrency = account.getCurrencyRatio();
    originalCurrencyAndValue = Tooltip(
      message: ratioCurrency.toString(),
      child: Row(
        children: <Widget>[
          Text(
            getAmountAsStringUsingCurrency(
              account.balance / ratioCurrency,
              iso4217code: account.fieldCurrency.value,
            ),
          ),
          const SizedBox(width: SizeForPadding.small),
          buildCurrencyWidget(account.fieldCurrency.value),
        ],
      ),
    );
  }

  return MyListItemAsCard(
    leftTopAsString: account.fieldName.value,
    leftBottomAsString: getTypeAsText(account.fieldType.value),
    rightTopAsString: getAmountAsStringUsingCurrency(account.balance),
    rightBottomAsWidget: originalCurrencyAndValue,
  );
}

/// Returns a widget displaying the currency of [account].
Widget buildAccountCurrencyWidget(Account account) {
  return buildCurrencyWidget(account.getAccountCurrencyAsText());
}
