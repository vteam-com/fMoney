import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/locale.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/pure/currency_label.dart';
import 'package:money/widgets/pure/theme_custom.dart';

const double _currencySpacing = 10;
const double _decimalFontScale = 0.8;

/// Formatted text using the supplied currency code and optional the currency/country flag

enum DataWidgetSize { body, title, header }

/// A stateless widget for widget from data.
class WidgetFromData extends StatelessWidget {
  /// Constructor
  const WidgetFromData({
    super.key,
    required this.amountModel,
    this.size = DataWidgetSize.body,
  });

  factory WidgetFromData.fromDouble(
    final double amount, [
    final DataWidgetSize size = DataWidgetSize.body,
  ]) {
    return WidgetFromData(
      amountModel: AmountModel(amount: amount),
      size: size,
    );
  }

  /// Amount to display
  final AmountModel amountModel;

  final DataWidgetSize size;

  @override
  Widget build(final BuildContext context) {
    if (amountModel.showCurrency) {
      return Row(
        children: <Widget>[
          _amountAsText(context),
          const SizedBox(width: _currencySpacing),
          buildCurrencyWidget(amountModel.iso4217),
        ],
      );
    } else {
      return _amountAsText(context);
    }
  }

  /// Builds the formatted amount text using monospaced font and scaled decimals.
  Widget _amountAsText(final BuildContext context) {
    double value = amountModel.asDouble();
    if (!value.isFinite) {
      value = 0.00;
    }

    double? fontSize;

    switch (size) {
      case DataWidgetSize.body:
        fontSize = getTextTheme(context).bodyMedium!.fontSize!;
      case DataWidgetSize.title:
        fontSize = getTextTheme(context).titleMedium!.fontSize!;
      case DataWidgetSize.header:
        fontSize = getTextTheme(context).headlineLarge!.fontSize!;
    }

    final TextStyle style = TextStyle(
      fontFamily: 'RobotoMono',
      color: context.colorTheme.getTextColorToUse(value, amountModel.autoColor),
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
    );

    final String valueAsString = getAmountAsStringUsingCurrency(
      isConsideredZero(value) ? 0.00 : value,
      iso4217code: amountModel.iso4217,
    );

    final int leftSideOfDecimalPoint = value.truncate();
    final String leftSideOfDecimalPointAsString = leftSideOfDecimalPoint.abs() == 0
        ? '' // No need to show leading zero
        : getAmountAsStringUsingCurrency(
            leftSideOfDecimalPoint,
            iso4217code: amountModel.iso4217,
            decimalDigits: 0,
          );

    final String rightOfDecimalPoint = valueAsString.substring(
      leftSideOfDecimalPointAsString.length,
    );

    return SelectableText.rich(
      maxLines: 1,
      textAlign: TextAlign.right,
      TextSpan(
        style: style,
        children: <InlineSpan>[
          TextSpan(text: leftSideOfDecimalPointAsString),
          TextSpan(
            text: rightOfDecimalPoint,
            style: TextStyle(fontSize: fontSize * _decimalFontScale),
          ),
        ],
      ),
    );
  }
}

/// Builds a currency label widget for a three-letter ISO4217 currency symbol.
Widget buildCurrencyWidget(String threeLetterCurrencySymbol) {
  final String flagId = getCountryFromCurrencyIso4217(threeLetterCurrencySymbol);

  return CurrencyLabel(
    threeLetterCurrencySymbol: getCurrencyAsString(threeLetterCurrencySymbol),
    flagId: flagId,
  );
}
