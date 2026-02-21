import 'package:flutter/material.dart';

/// Builds a column footer button with alignment and callbacks.
Widget buildColumnFooterButton({
  required final BuildContext context,
  required final TextAlign textAlign,
  required final int flex,
  required final VoidCallback? onPressed,
  required final VoidCallback? onLongPress,
  required final Widget? child,
}) {
  return Expanded(
    flex: flex,
    child: TextButton(
      style: ButtonStyle(
        shape: WidgetStateProperty.all<OutlinedBorder>(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Remove rounded corners
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: 3.0, // Left and right padding
          ),
        ),
      ),
      onPressed: onPressed,
      onLongPress: onLongPress,
      // clipBehavior: Clip.hardEdge,
      child: _alignChild(context, textAlign, child ?? const SizedBox()),
    ),
  );
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
