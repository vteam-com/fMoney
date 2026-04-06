import 'package:flutter/material.dart';
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
  Widget build(final BuildContext context) {
    final TextStyle style = TextStyle(
      fontFamily: 'RobotoMono',
      color: context.colorTheme.getTextColorToUseQuantity(quantity),
      fontWeight: FontWeight.w900,
    );

    final String originalString = formatDoubleUpToFiveZero(
      quantity,
      showPlusSign: true,
    );

    final int leftSideOfDecimalPoint = quantity.truncate();
    String leftSideOfDecimalPointAsString = '';
    if (leftSideOfDecimalPoint != 0) {
      leftSideOfDecimalPointAsString = formatDoubleUpToFiveZero(
        leftSideOfDecimalPoint.toDouble(),
        showPlusSign: true,
      );
    }
    final String rightOfDecimalPoint = originalString.substring(
      leftSideOfDecimalPointAsString.length,
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
