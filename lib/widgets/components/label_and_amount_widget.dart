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
    this.onCaptionTap,
    this.small = false,
  });

  final double amount;
  final String caption;
  final String currencyIso4217;

  /// Optional callback invoked when the caption label is tapped.
  final VoidCallback? onCaptionTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final Widget amountWidget = WidgetFromData(
      amountModel: AmountModel(
        amount: amount,
        iso4217: currencyIso4217,
        showCurrency: false,
        autoColor: true,
      ),
    );

    return Row(
      children: <Widget>[
        Expanded(
          child: onCaptionTap == null
              ? Text(
                  caption,
                  style: small ? getTextTheme(context).bodySmall : getTextTheme(context).bodyMedium,
                )
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onCaptionTap,
                    child: Text(
                      caption,
                      style: small ? getTextTheme(context).bodySmall : getTextTheme(context).bodyMedium,
                    ),
                  ),
                ),
        ),
        amountWidget,
      ],
    );
  }
}
