import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/pure/quantity_widget.dart';

/// A stateless widget for label and quantity.
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
