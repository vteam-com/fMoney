import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';

const double _quantityFractionalFontSize = 11.0;

/// Formatted text using the supplied currency code and optional the currency/country flag
class QuantityWidget extends StatelessWidget {
  /// Constructor
  const QuantityWidget({
    required this.quantity,
    super.key,
    this.align = TextAlign.right,
  });

  final TextAlign align;

  /// Amount to display
  final double quantity;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontFamily: 'RobotoMono',
      color: context.colorTheme.getTextColorToUseQuantity(quantity),
      fontWeight: FontWeight.w900,
    );

    // formatDoubleUpToFiveZero always formats with the en_US '.' decimal separator
    final (String leftSideOfDecimalPointAsString, String rightOfDecimalPoint) = splitAtDecimalSeparator(
      formatDoubleUpToFiveZero(quantity, showPlusSign: true),
      '.',
    );

    return SelectableText.rich(
      maxLines: 1,
      textAlign: align,
      TextSpan(
        style: style,
        children: <InlineSpan>[
          TextSpan(text: leftSideOfDecimalPointAsString),
          if (rightOfDecimalPoint.isNotEmpty)
            TextSpan(
              text: rightOfDecimalPoint,
              style: const TextStyle(fontSize: _quantityFractionalFontSize),
            ),
        ],
      ),
    );
  }
}
