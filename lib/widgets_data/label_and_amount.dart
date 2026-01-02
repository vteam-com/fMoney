import 'package:money/helpers/color_helper.dart';
import 'package:money/models/money_model.dart';
import 'package:money/widgets/quantity_widget.dart';
import 'package:money/widgets_data/money_widget.dart';

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
        MoneyWidget(
          amountModel: MoneyModel(
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

class LabelAndQuantity extends StatelessWidget {
  const LabelAndQuantity({
    super.key,
    required this.caption,
    required this.quantity,
    this.small = false,
  });

  final String caption;
  final double quantity;
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
        QuantityWidget(quantity: quantity, align: TextAlign.right),
      ],
    );
  }
}
