import 'package:flutter/material.dart';
import 'package:money/helpers/constants_helper.dart';

/// Builds a column footer button with alignment and callbacks.
///
/// When [fixedWidth] is provided the button is wrapped in a [SizedBox] of that
/// width (for pixel-aligned layout); otherwise it is wrapped in an
/// [Expanded] with weight [flex] (for proportional flex layout).
Widget buildColumnFooterButton({
  required BuildContext context,
  required TextAlign textAlign,
  required int flex,
  required VoidCallback? onPressed,
  required VoidCallback? onLongPress,
  required Widget? child,
  double? fixedWidth,
}) {
  final Widget inner = TextButton(
    style: ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Remove rounded corners
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: SizeForPadding.small, // Left and right padding
        ),
      ),
    ),
    onPressed: onPressed,
    onLongPress: onLongPress,
    // clipBehavior: Clip.hardEdge,
    child: _alignChild(context, textAlign, child ?? const SizedBox()),
  );
  if (fixedWidth != null) {
    return SizedBox(width: fixedWidth, child: inner);
  }
  return Expanded(flex: flex, child: inner);
}

/// Aligns the footer cell content based on the requested [align] value.
Widget _alignChild(BuildContext _, TextAlign align, Widget content) {
  Alignment alignment = Alignment.center;

  switch (align) {
    case TextAlign.center:
      alignment = Alignment.center;

    case TextAlign.right:
    case TextAlign.end:
      alignment = Alignment.centerRight;

    case TextAlign.left:
    case TextAlign.start:
    default:
      alignment = Alignment.centerLeft;
  }

  return Stack(
    children: <Widget>[Align(alignment: alignment, child: content)],
  );
}
