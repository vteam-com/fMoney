import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/theme_custom.dart';
import 'package:money/widgets_data/money_object/currencies/currency.dart';
import 'package:money/widgets_data/money_object/money_model.dart';

/// Formatted text using the supplied currency code and optional the currency/country flag

enum MoneyWidgetSize { body, title, header }

class MoneyWidget extends StatelessWidget {
  /// Constructor
  const MoneyWidget({
    super.key,
    required this.amountModel,
    this.size = MoneyWidgetSize.body,
  });

  factory MoneyWidget.fromDouble(
    final double amount, [
    final MoneyWidgetSize size = MoneyWidgetSize.body,
  ]) {
    return MoneyWidget(
      amountModel: MoneyModel(amount: amount),
      size: size,
    );
  }

  /// Amount to display
  final MoneyModel amountModel;

  final MoneyWidgetSize size;

  @override
  Widget build(final BuildContext context) {
    if (amountModel.showCurrency) {
      return Row(
        children: <Widget>[
          _amountAsText(context),
          const SizedBox(width: 10),
          Currency.buildCurrencyWidget(amountModel.iso4217),
        ],
      );
    } else {
      return _amountAsText(context);
    }
  }

  Widget _amountAsText(final BuildContext context) {
    double value = amountModel.asDouble();
    if (!value.isFinite) {
      value = 0.00;
    }

    double? fontSize;

    switch (size) {
      case MoneyWidgetSize.body:
        fontSize = getTextTheme(context).bodyMedium!.fontSize!;
      case MoneyWidgetSize.title:
        fontSize = getTextTheme(context).titleMedium!.fontSize!;
      case MoneyWidgetSize.header:
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
            style: TextStyle(fontSize: fontSize * 0.8),
          ),
        ],
      ),
    );
  }
}
