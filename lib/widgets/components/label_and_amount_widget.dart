import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// A stateless widget for label and amount.
class LabelAndAmount extends StatelessWidget {
  const LabelAndAmount({
    super.key,
    required this.caption,
    required this.amount,
    this.currencyIso4217 = Constants.defaultCurrency,
    this.small = false,
  });

  final double amount;
  final String caption;
  final String currencyIso4217;
  final bool small;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            caption,
            style: small ? getTextTheme(context).bodySmall : getTextTheme(context).bodyMedium,
          ),
        ),
        WidgetFromData(
          amountModel: AmountModel(
            amount: amount,
            iso4217: currencyIso4217,
            showCurrency: false,
            autoColor: true,
          ),
        ),
      ],
    );
  }
}
